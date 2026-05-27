/*******************************************************************
* @ClassName          :   ARC_DocuSignHelper
* @Description        :   Utility methods for DocuSign management: Generate docusign data, templates, recipients, resend contract methods.
* @MethodName         :   getDependents, createRecipientsFromMembers, getTemplateId, createRecipients, createRecipients2, createMedicalQuestions,
 medicalQuestionsConstructorForDocuSign, removeMembers, createRecipientForAddMember, getMembersForPlans, isPublicGroupMember, filterMembersById
********************************************************************/


global without sharing class ARC_DocuSignHelper implements vlocity_ins.VlocityOpenInterface{
    Map<String, Object> docuSignData = new Map<String, Object>();
    Map<String, Object> medicalQuestions = new Map<String, Object>();
    Map<String, Object> primaryMedicalQuestions = new Map<String, Object>();
    List<Object> primaryPrescriptions = new List<Object>();
    Map<String, Object> spouseMedicalQuestions = new Map<String, Object>();
    List<Object> spousePrescriptions = new List<Object>();
    Map<String, Object> primary = new Map<String, Object>();
    Id primaryId = null;
    Map<String, Object> spouse = new Map<String, Object>();
    Id spouseId = null;
    List<Object> dependents = new List<Object>();
    Map<String, Object> info = new Map<String, Object>();
    Map<String, Object> payment = new Map<String, Object>();
    Map<String, Object> plan = new Map<String, Object>();
    Map<String, Object> medicalQuestionsOutMap = new Map<String, Object>();
    
    Map<String,Boolean> sectionA = new Map<String,Boolean>();
    Map<String, Boolean>  pastConditions = new Map<String, Boolean>();
    Map<String, String>  medicalConditionNotes = new Map<String, String>();
    Map<String, String>  primaryCareInformation = new Map<String, String>();
    Map<String, String>  prescriptionMedication = new Map<String, String>();
    
    Integer medicalNotesPosition = 1;
    Integer physicianPosition = 1;
    Integer medicationsPosition = 1;
    String noDate = 'N/A';
        
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        if (methodName == 'getDependents') {
            getDependents(inputMap, outputMap, options);
        }
        if (methodName == 'createRecipientsFromMembers') {
            createRecipientsFromMembers(inputMap, outputMap, options);
        }
        if (methodName == 'getTemplateId') {
            getTemplateId(inputMap, outputMap, options);
        }
        if (methodName == 'createRecipients') {
            createRecipients(inputMap, outputMap, options);
        }
        if (methodName == 'createRecipients2') {
            createRecipients2(inputMap, outputMap, options);
        }
        if (methodName == 'createMedicalQuestions') {
            createMedicalQuestions(inputMap, outputMap, options);
        }
        if (methodName == 'medicalQuestionsConstructorForDocuSign') {
            medicalQuestionsConstructorForDocuSign(inputMap, outputMap, options);
        }
        if (methodName == 'removeMembers') {
            removeMembers(inputMap, outputMap, options);
        }
        if (methodName == 'createRecipientForAddMember') {
            createRecipientForAddMember(inputMap, outputMap, options);
        }
        if (methodName == 'getMembersForPlans') {
            getMembersForPlans(inputMap, outputMap, options);
        }
        if (methodName == 'isPublicGroupMember') {
            isPublicGroupMember(inputMap, outputMap, options);
        }
        if (methodName == 'filterMembersById') {
            filterMembersById(inputMap, outputMap, options);
        }
        
        return true;
    }


    global void getMembersForPlans(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        
        List<Object> contractLineItemList = (List<Object>)inputMap.get('ContracLineItemList');
        String output = '';
        for (Integer i = 0 ; i<contractLineItemList.size(); i++) {
            Map<String, Object> cli = (Map<String, Object>) contractLineItemList[i];
            List<Object> GCMP = (List<Object>) cli.get('GCMP');
            
            String program = (String)cli.get('Program');
            output += program + ': ';
            for (Integer j = 0 ; j<GCMP.size(); j++) {
                Map<String,Object> member = (Map<String,Object>)GCMP[j];
                String memberName = (String)member.get('MemberName');
                output += ' ' + memberName + ',';
            }
            
            output = output.removeEnd(',');
            output += '\n';
        
        }
        outputMap.put('output', output);
    }
  

    global void medicalQuestionsConstructorForDocuSign(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        docuSignData = (Map<String, Object>)inputMap.get('DocuSignData');
        
        medicalQuestions = (Map<String, Object>)inputMap.get('MedicalQuestions');        
        
        
        primary = (Map<String, Object>)docuSignData.get('Primary');
        
        primaryId = (Id) primary.get('Id');
        
        
        try {
            spouse = (Map<String, Object>)docuSignData.get('Spouse');
            if (spouse != null) {
                spouseId = (Id) spouse.get('Id');
            }
        } catch(Exception e) {
            
        }
        
        try{
            if ((List<Object>)docuSignData.get('Dependents') != null) {
                dependents = (List<Object>)docuSignData.get('Dependents');            
            }
        }catch(Exception e) {
            
        }

        createMedicalNotes('RAD_ParentSiblingDiagnosed', 'ParentSiblingDiagnosed', 'TXT_MemberIdParentDiagnosed', 'CHKBOX_MemberParentDiagnosed', 'TXTAREA_MemberParentDiagnosed', 'DATE_MemberParentDiagnosed', 'TXT_MemberParentDiagnosed');
        
        createMedicalNotes('RAD_UnexplainedSymptoms', 'UnexpectedSymptoms', 'TXT_MemberIdUnexpectedSymptoms', 'CHKBOX_UnexpectedSymptoms', 'TXTAREA_MemberUnexpectedSymptoms',  'DATE_MemberUnexpectedSymptoms', 'TXT_MemberUnexpectedSymptoms');
        
        createMedicalNotes('RAD_Internations', 'Internations', 'TXT_MemberIdInternations', 'CHKBOX_Internations', 'TXTAREA_MemberInternations', 'DATE_MemberInternations', 'TXT_MemberInternations');
        
        createMedicalNotes('RAD_Addictions', 'Addictions', 'TXT_MemberIdAddictions', 'CHKBOX_Addictions', 'TXTAREA_MemberAddictions', 'DATE_MemberAddictions', 'TXT_MemberAddictions');
        
        createMedicalNotes('RAD_PendingTests', 'PendingTests', 'TXT_MemberIdPendingTests', 'CHKBOX_PendingTests', 'TXTAREA_MemberPendingTests', 'DATE_MemberPendingTests', 'TXT_MemberPendingTests');
        
        createMedicalNotes('RAD_Consults', 'Consults', 'TXT_MemberIdConsults', 'CHKBOX_Consulted', 'TXTAREA_MemberConsults', 'DATE_MemberConsults', 'TXT_MemberConsults');

        createMedicalNotes('RAD_LicenceSuspended', 'LicenceSuspended', 'TXT_MemberIdLicenceSuspended', 'CHKBOX_LicenceSuspended', 'TXTAREA_MemberLicenceSuspended', 'DATE_MemberLicenceSuspended', 'TXT_MemberLicenceSuspended');
        
        createMedicalNotes('RAD_Cancer', 'Cancers', 'TXT_MemberIdCancer', 'CHK_MemberBeenDiagnosedWithCancer', 'TXT_TypeOfCancer', 'DATE_Cancer', 'TXT_MemberNameCancer');

        createPastConditionsNotes();

        generatePastConditions();
        
        // getCancerInformation();
        
        createPhysicians();
        
        createPrescriptions();
        
        
        medicalQuestionsOutMap.put('SectionA', sectionA);
        medicalQuestionsOutMap.put('PastConditions', pastConditions);
        medicalQuestionsOutMap.put('MedicalConditionNotes',  medicalConditionNotes);
        medicalQuestionsOutMap.put('PrimaryCareInformation',  primaryCareInformation);
        medicalQuestionsOutMap.put('PrescriptionMedication',  prescriptionMedication);
        
        if (dependents.size() > 0) {
            docuSignData.remove('Dependents');
            docuSignData.put('Dependents', dependents);
        }
        
        if (spouse != null) {
            docuSignData.remove('Spouse');
            docuSignData.put('Spouse', spouse);
        }
        
        docuSignData.remove('Primary');
        docuSignData.put('Primary', primary);
        
        info = (Map<String, Object>)docuSignData.get('Info');
        docuSignData.put('Info', info);
        
        payment = (Map<String, Object>)docuSignData.get('Payment');
        docuSignData.put('Payment', payment);
        
        plan = (Map<String, Object>)docuSignData.get('Plan');
        docuSignData.put('Plan', plan);
        
        docuSignData.put('MedicalQuestions', medicalQuestionsOutMap);

        outputMap.remove('DocuSignData');
        outputMap.put('DocuSignData', docuSignData);
    }
    
    global void createMedicalNotes(String radioButton, String medicalQuestionName, String memberIdName, String checkBox, String notes, String dateOf, String memberNameCondition) {
        System.debug('medicalQuestionName =>'+medicalQuestionName);
        String radioButtonValue = '';
        try{
            radioButtonValue = (String) medicalQuestions.get(radioButton);
        }catch(Exception e) {
            
        }    
        if (radioButtonValue == 'Yes') {
            System.debug('radioButtonValue: ' + radioButtonValue);
            List<Object> medicalQuestionList = new List<Object>();
            try{
                medicalQuestionList = (List<Object>)medicalQuestions.get(medicalQuestionName);
                
            }catch(Exception e) {
                
            }
            //loop all members for a medical question
            System.debug(medicalQuestionName);
            System.debug(medicalQuestionList.size());
            
            for (Integer i = 0; i < medicalQuestionList.size(); i++) {
                Map<String, Object> medicalQuestion = (Map<String, Object>)medicalQuestionList.get(i);
                
                if (medicalQuestion != null) {       
                    System.debug('medicalQuestion: ' + medicalQuestion);        
                    Id memberId = (Id) medicalQuestion.get(memberIdName);
                    
                    Boolean bool = false;
                    if (medicalQuestion.get(checkBox) != null) {
                        bool = (Boolean) medicalQuestion.get(checkBox);
                    }
                    System.debug('bool: ' + bool);
                    // if the checkbox is true gets the question info for that member, creates medical Condition information and adds it to medicalConditionList
                    if (bool) {
                        // get data elements 
                        String memberName = (String) medicalQuestion.get(memberNameCondition);
                        String medicalQuestionNote = String.valueOf(medicalQuestion.get(notes));
                        String medicalQuestionDateTime = (String)medicalQuestion.get(dateOf);  
                        System.debug('memberName: ' + memberName);
                        System.debug('medicalQuestionNote: ' + medicalQuestionNote);
                        System.debug('medicalQuestionDateTime: ' + medicalQuestionDateTime);

                        String medicalQuestionDate = '';
                        if (medicalQuestionNote == null) {
                            medicalQuestionNote = 'N/A';
                        }
                        if (medicalQuestionDateTime == null) {
                            medicalQuestionDate = 'N/A';
                        }else{
                            medicalQuestionDate = parseDate(medicalQuestionDateTime);
                        }

                        if (medicalQuestionDate != 'N/A' || medicalQuestionNote != 'N/A') {
                            String memberNameRow = 'MemberRow' + medicalNotesPosition;
                            // String relatedMedicalIssueRow = 'Related Medical IssueRow' + medicalNotesPosition;
                            String noteRow = 'NoteRow' + medicalNotesPosition;
                            String dateRow = 'DateRow' + medicalNotesPosition;
                            medicalConditionNotes.put(memberNameRow, memberName);
                            // medicalConditionNotes.put(relatedMedicalIssueRow, medicalQuestionName);
                            medicalConditionNotes.put(noteRow, medicalQuestionName+': '+medicalQuestionNote);
                            medicalConditionNotes.put(dateRow, medicalQuestionDate);
            
                            medicalNotesPosition++;
                        }
                        
                        ///// SectionA elements creation ////
                        String nodeName = 'SectionA '; 
                        System.debug('memberId: ' + memberId);
                        System.debug('primaryId: ' + primaryId);
                        System.debug('spouseId: ' + spouseId);
                        if (memberId == primaryId) {
                            System.debug('primary');
                            nodeName = nodeName + 'Primary '+ medicalQuestionName;
                            System.debug(nodeName);
                        } else if (memberId == spouseId) {
                            System.debug('spouse');
                            nodeName = nodeName + 'Spouse '+ medicalQuestionName;
                        } else{
                                    System.debug('dependent');
                            for (Integer j = 0; j < dependents.size(); j++) {
                                Map<String, Object> dependent = (Map<String, Object>)dependents.get(j);
                                Id dependentId = (Id) dependent.get('Id');
                                if (memberId == dependentId) {
                                    System.debug('dependent si es un');
                                    Integer DependentNr = j+1;
                                    nodeName = nodeName + 'Dependent' + DependentNr + ' ' + medicalQuestionName;
                                }
                            }
                        }
                        System.debug(nodeName);
                        sectionA.put(nodeName, bool);
                    }
                }


            }
        }
    }

    


    public void generatePastConditions() {
        String hasPastConditions = '';
        List<Object> pastConditionsList = new List<Object>();
        try{
            hasPastConditions = (String) medicalQuestions.get('RAD_PastConditions');
            pastConditionsList = (List<Object>)medicalQuestions.get('PastConditions');
        }catch(Exception e) {
            
        }
        if (hasPastConditions == 'Yes') {
            // loops all past conditions
            // {
            //     "TXT_MemberOtherPastConditions": "othersssss",
            //     "MULSEL_Conditions": "Alcohol Abuse;ALS;Alzheimer’s Disease;Abdominal Aortic Aneurysm;Aneurysm, Cerebral;Autism Spectrum Disorders;Bipolar with 2 or more current medications;Cerebral Palsy;Chronic Obstructive Pulmonary Disease (COPD);Chronic Kidney Disease, stage 3b, 4 or 5;Cystic Fibrosis;Dementia;Diabetes, Type I;Diabetes, Type 2 when taking 2 heart medications, or have kidney/liver disease;Down’s Syndrome;Ectasia;Emphysema;Fragile X Syndrome;Fibromyalgia (w/ treatment);Hepatitis (Chronic Viral B & C);HIV/AIDS;Lupus;Macular Degeneration (wet or dry);Marfan’s Syndrome;Morbid Obesity (BMI > 40);Multiple Sclerosis;Muscular Dystrophy;Paralysis;Parkinson’s Disease;Rheumatoid Arthritis w/ biologic treatment;Schizophrenia with 2 or more current medications;Sickle-Cell Disease;Sjogren Syndrome;Spina Bifida;Systemic Lupus Erythematosus;Typhoid;Underweight (BMI <15);Inpatient Psychiatric Treatment within past 5 years;Treatment with Naloxone, Suboxone, Methadone or any other medication to treat addiction within the past 5 years",
            //     "TXT_MemberIdPastConditions": "a3q8K00000014vwQAA",
            //     "TXT_MemberPastConditions": "Pasta Italiana"
            // }
            Map<String,String> pastConditionIndex = getPastConditionIndex();
            for (Object pastCondition : pastConditionsList) {
                String memberId = (String)((Map<String,Object>)pastCondition).get('TXT_MemberIdPastConditions');
                if ( ((Map<String,Object>)pastCondition).containsKey('MULSEL_Conditions')) {
                    List<String> pastConditionList = (List<String>)((String)((Map<String,Object>)pastCondition)?.get('MULSEL_Conditions'))?.split(';');
                    System.debug(pastConditionsList);
                    for (String pastConditionElement : pastConditionList) {
                        String pastConditionName = pastConditionIndex.get(pastConditionElement);
                        String nodeName = '';
                        String relationship = '';
                        if (memberId == primaryId) {
                            nodeName = 'P.'+pastConditionName;
                            relationship = 'Primary';
                        } else if (memberId == spouseId) {
                            nodeName = 'S.'+pastConditionName;
                            relationship = 'Spouse';
                        } else{
                            Integer dependentNumber = 1;
                            for (Object dependent : dependents) {
                                Id dependentId =(Id)((Map<String,Object>)pastCondition)?.get('TXT_MemberIdPastConditions');
                                Id instanceMemberId =  (Id) ((Map<String,Object>)dependent)?.get('Id');
                                if (instanceMemberId == dependentId) {
                                    nodeName = 'D' + dependentNumber + '.' + pastConditionName;
                                    relationship = 'Dependent' + dependentNumber;
                                }
                                dependentNumber++;
                            }
                        }
                        pastConditions.put(nodeName, true);
                        sectionA.put('SectionA '+relationship+' PastConditions', true);
                    }
                }
            }
        }
    }

    global void createPastConditionsNotes() {
        String hasPastConditions = '';
        List<Object> pastConditionsList = new List<Object>();
        try{
            hasPastConditions = (String) medicalQuestions.get('RAD_PastConditions');
            pastConditionsList = (List<Object>)medicalQuestions.get('PastConditions');
        }catch(Exception e) {
            
        }
        if (hasPastConditions == 'Yes') {
            // loops all past conditions
            for (Integer i = 0; i < pastConditionsList.size(); i++) {
                Map<String, Object> pc = (Map<String, Object>)pastConditionsList.get(i);
                if (pc != null) {
                    //get the data for each past condition registered (there is one element per member)
                    Id memberId = (Id) pc.get('TXT_MemberIdPastConditions');
                    String memberName = String.valueOf( pc.get('TXT_MemberPastConditions'));
                    String conditions = '';
                    String otherConditions = String.valueOf(pc.get('TXT_MemberOtherPastConditions'));

                    // generate conditions string
                    String contractReason = (String)info.get('ContractReson');
                    Boolean isProgramChange = new Set<String>{'Add Member','Program Upgrade','Program Downgrade','Remove Member','Add Newborn','Ancillary Change','Remove Ancillary'}.contains(contractReason);
                    conditions = pc.get('MULSEL_Conditions') != null ? (String)pc.get('MULSEL_Conditions') : '';
                    conditions = conditions.replace(';', ', ');
                    if (otherConditions != null) {
                        conditions = (isProgramChange? conditions + ', ':'') + otherConditions;
                    }
                    if (conditions != '') {
                        String memberNameRow = 'MemberRow' + medicalNotesPosition;
                        String relatedMedicalIssueRow = 'Related Medical IssueRow' + medicalNotesPosition;
                        String noteRow = 'NoteRow' + medicalNotesPosition;
                        String dateRow = 'DateRow' + medicalNotesPosition;
                        medicalConditionNotes.put(memberNameRow, memberName);
                        medicalConditionNotes.put(relatedMedicalIssueRow, 'Pre-Existing Conditions');
                        medicalConditionNotes.put(noteRow, conditions);
                        medicalConditionNotes.put(dateRow, noDate);
                        
                        medicalNotesPosition++;
                    }
                }
            }
        }
    }

    global void getCancerInformation() {
        String isCancerInformation = '';
        try{
            isCancerInformation = (String) medicalQuestions.get('RAD_Cancer');
        }catch(Exception e) {
            
        }
        if (isCancerInformation == 'Yes') {
            List<Object> cancerGeneralData = (List<Object>)medicalQuestions.get('Cancers');
            //get the data for condition registered
            if (cancerGeneralData != null) {
                for (Integer i = 0; i < cancerGeneralData.size(); i++) {
                    //create new new element data map for inserting in medicalCondtionsList
                    Map<String, Object> medicalConditionData = new Map<String, Object>();
                    //get node info
                    Map<String, Object> cancerMemberInfo = (Map<String, Object>)cancerGeneralData.get(i);
                    String memberId = (String)cancerMemberInfo.get('TXT_MemberIdCancer');
                    String memberName = (String)cancerMemberInfo.get('TXT_MemberNameCancer');
                    String typeOfcancer = (String)cancerMemberInfo.get('TXT_TypeOfCancer');
                    Boolean underTreatment = (Boolean)cancerMemberInfo.get('CHK_CheckCancer');
                    String dateTimeOfcancer = (String)cancerMemberInfo.get('DATE_Cancer');
                    String dateOfcancer = '';
                    
                    if (dateTimeOfcancer != null) {
                        dateOfcancer = parseDate(dateTimeOfcancer);
                    }
                    if (underTreatment) {
                        typeOfcancer = typeOfcancer + ' (under treatment)';
                    }
                    String memberNameRow = 'MemberRow' + medicalNotesPosition;
                    String relatedMedicalIssueRow = 'Related Medical IssueRow' + medicalNotesPosition;
                    String noteRow = 'NoteRow' + medicalNotesPosition;
                    String dateRow = 'DateRow' + medicalNotesPosition;
                    medicalConditionNotes.put(memberNameRow, memberName);
                    medicalConditionNotes.put(relatedMedicalIssueRow, 'Cancer');
                    medicalConditionNotes.put(noteRow, typeOfcancer);
                    medicalConditionNotes.put(dateRow, dateOfcancer);
                    
                    medicalNotesPosition++;
                }
            }
        }
    }

    global void createPhysicians() {
        List<Object> physiciansList = new List<Object>();
        try{
            physiciansList = (List<Object>)medicalQuestions.get('Physicians');
        }catch(Exception e) {
            
        }
        if (physiciansList != null) {
            for (Integer i = 0; i < physiciansList.size(); i++) {
                Map<String, Object> physicianInfo = (Map<String, Object>)physiciansList.get(i);
                
                String memberName = (String) physicianInfo.get('CensusMemberName');
                String physicianName = (String) physicianInfo.get('PhysicianName');
                String physicianCity = (String) physicianInfo.get('PhysicianCity');
                String physicianPhone = (String) physicianInfo.get('PhysicianPhone');
                String physicianDiagnosis = (String) physicianInfo.get('Diagnosis');
                String physicianControlled = String.valueOf(physicianInfo.get('Controlled'));
                String physicianYearDiagnosedDateTime = (String) physicianInfo.get('YearDiagnosed');
                String physicianYearDiagnosed = '';
                if (physicianYearDiagnosedDateTime != null) {
                    physicianYearDiagnosed = parseDate(physicianYearDiagnosedDateTime);
                }
                if (physicianControlled == 'true') {
                    physicianControlled = 'X';
                }else{
                    physicianControlled = '';
                }
                
                String pageSuffix = '_3';
                
                String memberNameRow = 'MemberRow' + physicianPosition + pageSuffix;
                String physicianNameRow = 'Physician NameRow' + physicianPosition;
                String cityRow = 'CityRow' + physicianPosition;
                String phoneRow = 'PhoneRow' + physicianPosition;
                String diagnosisRow = 'DiagnosisRow' + physicianPosition;
                String controlledRow = 'ControlledRow' + physicianPosition;
                String yrDiagnosedRow = 'Yr DiagnosedRow' + physicianPosition;
                primaryCareInformation.put(memberNameRow, memberName);
                primaryCareInformation.put(physicianNameRow, physicianName);
                primaryCareInformation.put(cityRow, physicianCity);
                primaryCareInformation.put(phoneRow, physicianPhone);
                primaryCareInformation.put(diagnosisRow, physicianDiagnosis);
                primaryCareInformation.put(controlledRow, physicianControlled);
                primaryCareInformation.put(yrDiagnosedRow, physicianYearDiagnosed);
                
                physicianPosition++;
                
            }
        }
    }

    global void createPrescriptions() {
        String hasPrescriptions = '';
        try{
            hasPrescriptions = (String) medicalQuestions.get('RAD_PrescriptionMedications');
        }catch(Exception e) {
            
        }
        if (hasPrescriptions == 'Yes') {
            List<Object> prescriptionList = (List<Object>)medicalQuestions.get('Prescriptions');
            for (Integer i = 0; i < prescriptionList.size(); i++) {
                Map<String, Object> prescription = (Map<String, Object>)prescriptionList.get(i);
                String datePrescribed = '';
                String dateDiscontinued = '';

                Id memberId = (Id) prescription.get('MemberIdPrescription');
                String memberName = (String) prescription.get('MemberName');
                String nameOfMedication = (String) prescription.get('NameOfMedication');
                String reasonForMedication = (String) prescription.get('ReasonForMedication');
                String dateTimePrescribed = (String) prescription.get('DatePrescribed');
                String dateTimeDiscontinued = (String) prescription.get('DateDiscontinued');
                String prescPhysician = (String) prescription.get('PrescribingPhysician');
                
               
                if (dateTimePrescribed != null) {
                    datePrescribed = parseDate(dateTimePrescribed);
                }
                if (dateTimeDiscontinued != null) {
                    dateDiscontinued = parseDate(dateTimeDiscontinued);
                }
                
                String memberNameRow = 'Family MemberRow' + medicationsPosition;
                String nameOfMedicationRow = 'Name of MedicationRow' + medicationsPosition;
                String reasonForMedicationRow = 'Reason for MedicationRow' + medicationsPosition;
                String datePrescribedRow = 'Date prescribed MoYrRow' + medicationsPosition;
                String dateDiscontinuedRow = 'Date Discontinued MoYrRow' + medicationsPosition;
                String prescPhysicianRow = 'Prescribing PhysicianRow' + medicationsPosition;
                prescriptionMedication.put(memberNameRow, memberName);
                prescriptionMedication.put(nameOfMedicationRow, nameOfMedication);
                prescriptionMedication.put(reasonForMedicationRow, reasonForMedication);
                prescriptionMedication.put(datePrescribedRow, datePrescribed);
                prescriptionMedication.put(dateDiscontinuedRow, dateDiscontinued);
                prescriptionMedication.put(prescPhysicianRow, prescPhysician);

                medicationsPosition++;
            }
        }
    }

    private string parseDate(String aDateTime) {
        String aDate = aDateTime.split('T')[0];
        return aDate;
    }

    global static void createRecipientForAddMember(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        List<Object> userInputs = (List<Object>)inputMap.get('userInputs');
        List<Object> memberIds = (List<Object>)inputMap.get('memberIds');
        Boolean isAddMember = (Boolean)inputMap.get('isAddMember');
        String signerEmail = (String) inputMap.get('signerEmail');
        List<Map<String, Object>> recipients = new List<Map<String, Object>>();

        Integer dependentCount = 1;    
        Boolean hasFuturePrimary = false;
        Boolean hasPrimaryRecipient = false;
        

        for (Integer i = 0; i < userInputs.size(); i++) {
            Map<String, Object> userInput = (Map<String, Object>)userInputs.get(i);
            if ((String) userInput.get('CensusMemberRelationship') == 'Future Primary') hasFuturePrimary= true;       
            if ((Boolean)userInput.get('RF_Census.CM_IsPrimary') == true && (Integer) userInput.get('RF_Census.CM_Age')>=18) hasPrimaryRecipient= true;       
        }
        
        for (Integer i = 0; i < userInputs.size(); i++) {
            Map<String, Object> userInput = (Map<String, Object>)userInputs.get(i);
            String memberId =  (String)userInput.get('CensusMemberIdentifier');
            
            
            
            Integer age = (Integer) userInput.get('RF_Census.CM_Age');
            
            if (age >= 18) {
                Map<String, Object> recipient = new Map<String, Object>();
                
                String interKey = 'interKey-' + recipients.size();
                String templateRole = '';
                
                Boolean isPrimary = (Boolean) userInput.get('RF_Census.CM_IsPrimary');
                Boolean isSpouse = (Boolean) userInput.get('RF_Census.CM_IsSpouse');
                String name = (String) userInput.get('CensusMemberName');
            
                
                
                
                if (isPrimary) {
                    templateRole = 'Primary';
                    recipient.put('interKey', interKey);
                    recipient.put('routingOrder', null);
                    recipient.put('templateRole', templateRole);
                    recipient.put('signerEmail', signerEmail);
                    recipient.put('signerName', name);
                    recipients.add(recipient);
                }
                else if (isAddMember && memberIds.contains(memberId)) {
                    if (isSpouse) {
                        templateRole = 'Spouse';
                    }
                    else {
                        templateRole = 'Dependent' + dependentCount;
                        dependentCount++;
                    }
                    recipient.put('interKey', interKey);
                    recipient.put('routingOrder', null);
                    recipient.put('templateRole', templateRole);
                    recipient.put('signerEmail', signerEmail);
                    recipient.put('signerName', name);
                    recipients.add(recipient);
                }    
            }
        }
        if (recipients.size() == 0 || !hasPrimaryRecipient) {
            Map<String, Object> recipient = new Map<String, Object>();

            String interKey = 'interKey-' + recipients.size();
            String templateRole = 'Primary';
            Map<String, Object> guardian =  new Map<String, Object>();
            String email = '';
            String name = '';
            if (inputMap.get('Guardian') != '') {
                guardian = (Map<String, Object>)inputMap.get('Guardian');
                email = (String)guardian.get('Email');
                name = (String)guardian.get('Name');
            }
            recipient.put('interKey', interKey);
            recipient.put('routingOrder', null);
            recipient.put('templateRole', templateRole);
            recipient.put('signerEmail', email);
            recipient.put('signerName', name);

            recipients.add(recipient);
        }

        outputMap.put('Recipients', recipients);
    }

    global static void createRecipients(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        List<Object> userInputs = (List<Object>)inputMap.get('userInputs');
        String primaryEmail = (String) inputMap.get('primaryMemberEmail');

        List<Map<String, Object>> recipients = new List<Map<String, Object>>();

        Integer dependentCount = 1;
        Boolean hasFuturePrimary = false;

        for (Integer i = 0; i < userInputs.size(); i++) {
            Map<String, Object> userInput = (Map<String, Object>)userInputs.get(i);
            if ((String) userInput.get('Relationship') == 'Future Primary') hasFuturePrimary= true;       
        }

        for (Integer i = 0; i < userInputs.size(); i++) {
            Map<String, Object> userInput = (Map<String, Object>)userInputs.get(i);

            Integer age = (Integer) userInput.get('RF_Census.CM_Age');

            if (age >= 18) {
                Map<String, Object> recipient = new Map<String, Object>();

                String interKey = 'interKey-' + recipients.size();
                String templateRole = '';

                String relationship = (String) userInput.get('Relationship');
                String name = (String) userInput.get('CensusMemberName');

                if (relationship == 'Primary' && !hasFuturePrimary) {
                    templateRole = 'Primary';
                } else if (relationship == 'Primary' && hasFuturePrimary) {
                    templateRole = 'Dependent' + dependentCount;
                    dependentCount++;
                } else if (relationship == 'Spouse') {
                    templateRole = 'Spouse';
                } else if (relationship == 'Child') {
                    templateRole = 'Dependent' + dependentCount;
                    dependentCount++;
                }
                else if (relationship == 'Future Primary') {
                    templateRole = 'Primary';
                }

                recipient.put('interKey', interKey);
                recipient.put('routingOrder', null);
                recipient.put('templateRole', templateRole);
                recipient.put('signerEmail', primaryEmail);
                recipient.put('signerName', name);

                recipients.add(recipient);
            }
            
        }
        if (recipients.size() == 0) {
            Map<String, Object> recipient = new Map<String, Object>();

            String interKey = 'interKey-' + recipients.size();
            String templateRole = 'Primary';
            Map<String, Object> guardian =  new Map<String, Object>();
            String email = '';
            String name = '';
            if (inputMap.get('Guardian') != '') {
                guardian = (Map<String, Object>)inputMap.get('Guardian');
                email = (String)guardian.get('Email');
                name = (String)guardian.get('Name');
            }

            recipient.put('interKey', interKey);
            recipient.put('routingOrder', null);
            recipient.put('templateRole', templateRole);
            recipient.put('signerEmail', email);
            recipient.put('signerName', name);

            recipients.add(recipient);
        }

        outputMap.put('Recipients', recipients);
    }

    global void createRecipients2(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        docuSignData = (Map<String, Object>)inputMap.get('DocuSignData');

        if ((Map<String, Object>)docuSignData.get('Primary') != null) {
            primary = (Map<String, Object>)docuSignData.get('Primary');
        }

        spouse = (Map<String, Object>)docuSignData.get('Spouse');

        if ((List<Object>)docuSignData.get('Dependents') != null) {
            dependents = (List<Object>)docuSignData.get('Dependents');
        }

        String primaryEmail = (String) inputMap.get('PrimaryMemberEmail');

        List<Map<String, Object>> recipients = new List<Map<String, Object>>();

        Map<String, Object> primaryRecipient = new Map<String, Object>();

        String interKey = 'interKey-' + recipients.size();

        primaryRecipient.put('interKey', interKey);
        primaryRecipient.put('routingOrder', null);
        primaryRecipient.put('templateRole', 'Primary');
        primaryRecipient.put('signerEmail', primaryEmail);
        primaryRecipient.put('signerName', primary.get('Name'));

        recipients.add(primaryRecipient);

        if (spouse != null) {
            Map<String, Object> spouseRecipient = new Map<String, Object>();
            Decimal spouseAge = (Decimal) spouse.get('Age');
            if (spouseAge >= 18) {
                interKey = 'interKey-' + recipients.size();

                spouseRecipient.put('interKey', interKey);
                spouseRecipient.put('routingOrder', null);
                spouseRecipient.put('templateRole', 'Spouse');
                spouseRecipient.put('signerEmail', primaryEmail);
                spouseRecipient.put('signerName', spouse.get('Name'));

                recipients.add(spouseRecipient);
            }
        }

        if (dependents.size() > 0) {
            for (Integer i = 0; i < dependents.size(); i++) {
                Map<String, Object> dependent = (Map<String, Object>)dependents.get(i);

                Decimal age = (Decimal) dependent.get('Age');

                if (age >= 18) {
                    Map<String, Object> recipient = new Map<String, Object>();

                    interKey = 'interKey-' + recipients.size();
                    
                    String templateRole = 'Dependent' + (dependents.size()+1);
                    String name = (String) dependent.get('Name');

                    recipient.put('interKey', interKey);
                    recipient.put('routingOrder', null);
                    recipient.put('templateRole', templateRole);
                    recipient.put('signerEmail', primaryEmail);
                    recipient.put('signerName', name);

                    recipients.add(recipient);
                }
            }
        }

        outputMap.put('Recipients', recipients);
    }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////CREATE MEDICAL QUESTIONS/////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    global void createMedicalQuestions(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        docuSignData = (Map<String, Object>)inputMap.get('DocuSignData');
        medicalQuestions = (Map<String, Object>)inputMap.get('MedicalQuestions');        
        
        primary = (Map<String, Object>)docuSignData.get('Primary');
        primaryId = (Id) primary.get('Id');

        spouse = (Map<String, Object>)docuSignData.get('Spouse');
        if (spouse != null) {
            spouseId = (Id) spouse.get('Id');
        }

        if ((List<Object>)docuSignData.get('Dependents') != null) {
            dependents = (List<Object>)docuSignData.get('Dependents');            
        }

        for (Integer i = 0; i < dependents.size(); i++) {
            Map<String, Object> dependent = (Map<String, Object>)dependents.get(i);
            Map<String, Object> dependt = (Map<String, Object>)dependents[0];

            Map<String, Object> dependentMedicalQuestions = new Map<String, Object>();
            List<Object> prescriptions = new List<Object>();
            dependentMedicalQuestions.put('Prescriptions', prescriptions);
            dependent.put('MedicalQuestions', dependentMedicalQuestions);
        }

        createMedicalQuestion('RAD_UnexplainedSymptoms', 'UnexpectedSymptoms', 'TXT_MemberIdUnexpectedSymptoms', 'CHKBOX_UnexpectedSymptoms', 'TXTAREA_MemberUnexpectedSymptoms', 'DATE_MemberUnexpectedSymptoms');

        createMedicalQuestion('RAD_Internations', 'Internations', 'TXT_MemberIdInternations', 'CHKBOX_Internations', 'TXTAREA_MemberInternations', 'DATE_MemberInternations');

        createMedicalQuestion('RAD_Addictions', 'Addictions', 'TXT_MemberIdAddictions', 'CHKBOX_Addictions', 'TXTAREA_MemberAddictions', 'DATE_MemberAddictions');

        createMedicalQuestion('RAD_PendingTests', 'PendingTests', 'TXT_MemberIdPendingTests', 'CHKBOX_PendingTests', 'TXTAREA_MemberPendingTests', 'DATE_MemberPendingTests');

        createMedicalQuestion('RAD_Consults', 'Consults', 'TXT_MemberIdConsults', 'CHKBOX_Consulted', 'TXTAREA_MemberConsults', 'DATE_MemberConsults');

        //SECTION B 
        createPastConditions();
        // PCI & PM: - this information is now listed independently from the census members. 
        // PRIMARY CARE INFORMATION  
        //createPhysicians(); 


        //PRESCRIPTION MEDICATIONS
        //createPrescriptions();

        if (dependents.size() > 0) {
            docuSignData.remove('Dependents');
            docuSignData.put('Dependents', dependents);
        }

        
        if (spouse != null) {
            spouseMedicalQuestions.put('Prescriptions', spousePrescriptions);
            spouse.put('MedicalQuestions', spouseMedicalQuestions);
            docuSignData.remove('Spouse');
            docuSignData.put('Spouse', spouse);
        }
        
        primaryMedicalQuestions.put('Prescriptions', primaryPrescriptions);
        primary.put('MedicalQuestions', primaryMedicalQuestions);

        docuSignData.remove('Primary');
        docuSignData.put('Primary', primary);
        
        List<Object> physicians = (List<Object>)medicalQuestions.get('Physicians');
        docuSignData.put('Physicians', physicians);
        
        List<Object> prescriptions = (List<Object>)medicalQuestions.get('Prescriptions');
        docuSignData.put('Prescriptions', prescriptions);

        info = (Map<String, Object>)docuSignData.get('Info');
        docuSignData.put('Info', info);

        payment = (Map<String, Object>)docuSignData.get('Payment');
        docuSignData.put('Payment', payment);

        plan = (Map<String, Object>)docuSignData.get('Plan');
        docuSignData.put('Plan', plan);
        
        outputMap.remove('DocuSignData');
        outputMap.put('DocuSignData', docuSignData);
    }


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////CREATE MEDICAL QUESTION/////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    global void createMedicalQuestion(String radioButton, String medicalQuestionName, String memberIdName, String checkBox, String notes, String dateOf) {

        String radioButtonValue = (String) medicalQuestions.get(radioButton);
        if (radioButtonValue != 'No') {
            List<Object> medicalQuestionList = (List<Object>)medicalQuestions.get(medicalQuestionName);

            for (Integer i = 0; i < medicalQuestionList.size(); i++) {
                Map<String, Object> medicalQuestion = (Map<String, Object>)medicalQuestionList.get(i);
                Id memberId = (Id) medicalQuestion.get(memberIdName);
                // get the elements
                Boolean bool = (Boolean) medicalQuestion.get(checkBox);
                String medicalQuestionDate = (String)medicalQuestion.get(dateOf); 
                String medicalQuestionNote = (String)medicalQuestion.get(notes); 

                Map<String,String> medicalQuestionData = new Map<String,String>();
                String medicalQuestionDataNodeName = medicalQuestionName + 'Data';
                medicalQuestionData.put('Date', medicalQuestionDate);
                medicalQuestionData.put('Notes', medicalQuestionNote);

                // sort in primary spouse or dependents
                if (memberId == primaryId) {
                    primaryMedicalQuestions.put(medicalQuestionName, bool);
                    primaryMedicalQuestions.put(medicalQuestionDataNodeName, medicalQuestionData);
                } else if (memberId == spouseId) {
                    spouseMedicalQuestions.put(medicalQuestionName, bool);
                    spouseMedicalQuestions.put(medicalQuestionDataNodeName, medicalQuestionData);
                } else{
                    for (Integer j = 0; j < dependents.size(); j++) {
                        Map<String, Object> dependent = (Map<String, Object>)dependents.get(j);
                        Id dependentId = (Id) dependent.get('Id');
                        
                        if (memberId == dependentId) {
                            Map<String, Object> dependentMedicalQuestions = (Map<String, Object>)dependent.get('MedicalQuestions');
                            dependentMedicalQuestions.put(medicalQuestionName, bool);
                            dependentMedicalQuestions.put(medicalQuestionDataNodeName, medicalQuestionData);
                        }
                    }
                }
            }
        }
    }


   

    global void createPastConditions() {
        
        String isCancerInformation = (String) medicalQuestions.get('RAD_Cancer');
        String pastConditions = (String) medicalQuestions.get('RAD_PastConditions');
        if (pastConditions != 'No') {
            List<Object> EB_PastConditions = (List<Object>)medicalQuestions.get('PastConditions');
            for (Integer i = 0; i < EB_PastConditions.size(); i++) {
                Map<String, Object> medicalQuestion = (Map<String, Object>)EB_PastConditions.get(i);
                //get the data for each past condition registered (there is one element per member)
                Id memberId = (Id) medicalQuestion.get('TXT_MemberIdPastConditions');
                String conditions = (String) medicalQuestion.get('MULSEL_Conditions');
                String otherConditions = (String) medicalQuestion.get('TXT_MemberOtherPastConditions');

                if (conditions != null) {
                    conditions = conditions.replace(';', ', ');
                }
                if (otherConditions != null) {
                    conditions = conditions + ', ' + otherConditions;
                }

                String cancerInformation = '';
                if (isCancerInformation != 'No') {

                    List<Object> cancerGeneralData = (List<Object>)medicalQuestions.get('Cancers');
                    cancerInformation = getCancerInformationString(memberId, cancerGeneralData);

                }

                if (cancerInformation != '') {
                    conditions = conditions + '. Cancer: ' + cancerInformation;
                }

                // sort the medical conditions in nodes: primary, spouse or for dependents
                if (memberId == primaryId) {
                    primaryMedicalQuestions.put('PastConditions', conditions);
                } else if (memberId == spouseId) {
                    spouseMedicalQuestions.put('PastConditions', conditions);
                } else{
                    for (Integer j = 0; j < dependents.size(); j++) {
                        Map<String, Object> dependent = (Map<String, Object>)dependents.get(j);
                        Id dependentId = (Id) dependent.get('Id');
                        if (memberId == dependentId) {
                            Map<String, Object> dependentMedicalQuestions = (Map<String, Object>)dependent.get('MedicalQuestions');
                            dependentMedicalQuestions.put('PastConditions', conditions);
                        }
                    }
                }
            }
        }

        
    }

    global String getCancerInformationString(String memberId, List<Object> cancerGeneralData) {
        String cancerInformationString = '';

        for (Integer i = 0; i < cancerGeneralData.size(); i++) {
            Map<String, Object> cancerMemberInfo = (Map<String, Object>)cancerGeneralData.get(i);
            String memberIdOfcancer = (String)cancerMemberInfo.get('TXT_MemberIdCancer');
            // finds given memberId
            if (memberId == memberIdOfcancer) {
                String typeOfcancer = (String)cancerMemberInfo.get('TXT_TypeOfCancer');
                String dateOfcancer = (String)cancerMemberInfo.get('DATE_Cancer');
                cancerInformationString +=  typeOfcancer + ' - ' + dateOfcancer + ' '; 
            }
        }
        return cancerInformationString;
    }


    global void removeMembers(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        List<Object> removeMembers = new List<Object>();
        Boolean removedPrimary = false;
        try{
            docuSignData = (Map<String, Object>)inputMap.get('DocuSignData');
            
            primary = (Map<String, Object>)docuSignData.get('Primary');
            primaryId = (Id) primary.get('Id');

            spouse = (Map<String, Object>)docuSignData.get('Spouse');
            if (spouse != null) {
                spouseId = (Id) spouse.get('Id');
            }

            if ((List<Object>)docuSignData.get('Dependents') != null) {
                dependents = (List<Object>)docuSignData.get('Dependents');
            }

            removeMembers = (List<Object>)inputMap.get('RemoveMembers');
        } catch (Exception e) {

        }

        String removeMembersString = '';

        for (Integer i = 0; i < removeMembers.size(); i++) {
            Map<String, Object> removeMember = (Map<String, Object>)removeMembers.get(i);
            Id removeMemberId = (Id) removeMember.get('TXT_CensusMemberId');
            String name = '';
            String firstName = (String) removeMember.get('TXT_FirstNameEB');
            String lastName = (String) removeMember.get('TXT_LastNameEB');
            name = firstName + ' ' + lastName;
            removeMembersString += name;
            if (i != removeMembers.size() - 1) {
                removeMembersString += ', ';
            }
            if (removeMemberId == primaryId) {
                docuSignData.remove('Primary');
                removedPrimary = true;

            } else if (removeMemberId == spouseId) {
                docuSignData.remove('Spouse');
            } else{
                for (Integer j = 0; j < dependents.size(); j++) {
                    Map<String, Object> dependent = (Map<String, Object>)dependents.get(j);
                    Id dependentId = (Id) dependent.get('Id');
                    if (removeMemberId == dependentId) {
                        dependents.remove(j);
                    }
                }
            }
        }
        if (removedPrimary) {
            // List<Map<String, Object>> Primary = new List<Map<String, Object>>();
            Map<String, Object> newPrimary = new Map<String, Object>();
            String newPrimaryMemberId = (String) inputMap.get('newPrimaryMemberId');
            if ( newPrimaryMemberId != null ) {
                if ( spouseId == newPrimaryMemberId ) { 
                    newPrimary = spouse;
                } else {
                    for (Integer i = 0; i < dependents.size(); i++) {
                        Map<String, Object> d = (Map<String, Object>)dependents.get(i);
                        if ( d.get('Id') == newPrimaryMemberId ) { 
                            newPrimary = d;
                            break;
                        }        
                    }
                }
            } else {
                for (Integer i = 0; i < dependents.size(); i++) {
                    Map<String, Object> dependent1 = (Map<String, Object>)dependents.get(i);
                    String dob1String = (String)dependent1.get('DOB');
                    Date dob1 =  Date.valueOf(dob1String);
                    
                    for (Integer j = 0; j < dependents.size(); j++) {
                        Map<String, Object> dependent2 = (Map<String, Object>)dependents.get(j);
                        String dob2String = (String)dependent2.get('DOB');
                        Date dob2 = Date.valueOf(dob2String);
                        
                        if (dob1 > dob2) {
                            newPrimary = dependent1;
                        } else {
                            newPrimary = dependent2;
                        }
                    }
                }
            }
            // Primary.put('Primary', newPrimary);
            docuSignData.put('Primary', newPrimary);
            docuSignData.put('newPrimary', newPrimaryMemberId);
        }   
        
        if (dependents.size() > 0) {
            docuSignData.remove('Dependents');
            
            docuSignData.put('Dependents', dependents);
        }
      
        outputMap.put('RemoveMembers', removeMembersString);

        outputMap.remove('DocuSignData');
        outputMap.put('DocuSignData', docuSignData);
    }



    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////// METHODS FOR RESEND ENVELOPE //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////

    /*******************************************************************
    * @MethodName         :   getDependents
    * @Description        :   returns the list of members involved in the contract
    ********************************************************************/
    global void getDependents(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        List<vlocity_ins__GroupCensusMember__c> dependents = new List<vlocity_ins__GroupCensusMember__c>();
        String contractId = (String)inputMap.get('contractId');
        try {
            dependents  = [SELECT id, Name, vlocity_ins__CensusId__c, ARC_Relationship__c, ARC_Age__c, vlocity_ins__IsPrimaryMember__c, vlocity_ins__Email__c FROM vlocity_ins__GroupCensusMember__c WHERE id IN (SELECT vlocity_ins__GroupCensusMemberId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId ) ] ;
            outputMap.put('Dependents', dependents);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /*******************************************************************
    * @MethodName         :   createRecipientsFromMembers
    * @Description        :   Returns the recipients node to pass to the DocuSign Envelope Action from a list of census members (vlocity_ins__GroupCensusMember__c)
    ********************************************************************/
    global void createRecipientsFromMembers(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = (List<vlocity_ins__GroupCensusMember__c>)inputMap.get('censusMemberList');

        // Find the primary member email in the list of census members.
        String primaryEmail = '';
        String newPrimaryEmail = '';
        vlocity_ins__GroupCensusMember__c newPrimary;
        for (vlocity_ins__GroupCensusMember__c censusMember: censusMemberList) {
            if ((Boolean)censusMember.vlocity_ins__IsPrimaryMember__c) {
                primaryEmail = (String)censusMember.vlocity_ins__Email__c;
            }
            if ((String)censusMember.ARC_Relationship__c == 'Future Primary') {
                newPrimaryEmail = (String)censusMember.vlocity_ins__Email__c;
                newPrimary = censusMember;
            }
        }

        String contractReasons = (String)inputMap.get('ContractReasons');
        List<String> reasonList = contractReasons.split(';');
        Boolean isPrimaryChange = false;
        Boolean isAddMember = false;
        Boolean isAddExistingMember = false;
        Boolean oldPrimaryFound = false;
        Boolean newPrimaryFound = false;
        for (String reason : reasonList) {
            if (reason == 'Primary Change') {
                isPrimaryChange = true;
            } else if (reason == 'Add Member') {
                isAddMember = true;
            } else if (reason == 'Add Existing Member') {
                isAddExistingMember = true;
            }
        }

        // Find old members
        Id oldContractId = (Id)inputMap.get('OldContractId');
        Set<Id> oldMemberIds = new Set<Id>();
        vlocity_ins__GroupCensusMember__c oldPrimary;
        if (oldContractId != null) {
            List<vlocity_ins__GroupCensusMember__c> oldMembers = [
                SELECT Id, vlocity_ins__IsPrimaryMember__c, vlocity_ins__Email__c, Name, ARC_Age__c
                FROM vlocity_ins__GroupCensusMember__c 
                WHERE Id IN (
                    SELECT vlocity_ins__GroupCensusMemberId__c 
                    FROM vlocity_ins__GroupCensusMemberPlan__c 
                    WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :oldContractId
                )];
            for (vlocity_ins__GroupCensusMember__c cm : oldMembers) {
                oldMemberIds.add(cm.Id);
                if (cm.vlocity_ins__IsPrimaryMember__c) {
                    oldPrimary = cm;
                }
            }
        }

        System.debug('oldContractId: ' + oldContractId);
        System.debug('oldMemberIds: ' + oldMemberIds);
        System.debug('contractReasons: ' + contractReasons);

        // create the recipients list
        List<Map<String, Object>> recipients = new List<Map<String, Object>>();
        Integer dependentCount;
        if (contractReasons.contains('Primary Change')) {
            dependentCount = 2;
        } else {
            dependentCount = 1;
        }
        // populate the list with all census members provided that are 18+
        for (vlocity_ins__GroupCensusMember__c censusMember: censusMemberList) {
            Integer age = (Integer)censusMember.ARC_Age__c;

            if (age >= 18) {
                Map<String, Object> recipient = new Map<String, Object>();
                String interKey = 'interKey-' + recipients.size();
                String templateRole = '';
                String relationship = (String)censusMember.ARC_Relationship__c;
                String name = (String)censusMember.Name;
                String censusMemberId = (String)censusMember.Id;
                String email;

                if (((isAddMember || isAddExistingMember) && oldMemberIds.contains(censusMemberId)) && (relationship == 'Spouse' || relationship == 'Child')) continue;

                if (isPrimaryChange) {
                    if (relationship == 'Future Primary') {
                        email = newPrimaryEmail;
                        newPrimaryFound = true;
                        templateRole = 'Primary';
                    } else if (relationship == 'Primary') {
                        email = primaryEmail;
                        oldPrimaryFound = true;
                        templateRole = 'Dependent1';
                    } else if (relationship == 'Spouse') {
                        email = newPrimaryEmail;
                        templateRole = 'Spouse';
                    } else if (relationship == 'Child') {
                        templateRole = 'Dependent' + dependentCount;
                        email = newPrimaryEmail;
                        dependentCount++;
                    }
                } else {
                    email = primaryEmail;
                    if (relationship == 'Primary') {
                        templateRole = 'Primary';
                    } else if (relationship == 'Spouse') {
                        templateRole = 'Spouse';
                    } else if (relationship == 'Child') {
                        templateRole = 'Dependent' + dependentCount;
                        dependentCount++;
                    }
                }

                recipient.put('interKey', interKey);
                recipient.put('routingOrder', null);
                recipient.put('templateRole', templateRole);
                recipient.put('signerEmail', email);
                recipient.put('signerName', name);
                recipient.put('memberOrContactId', censusMemberId);
                recipient.put('isGuardian', false);

                recipients.add(recipient);
            }
        }
        // If there are no +18 members, populate with the guardian's information.
        if (recipients.size() == 0 || (recipients.size() != 0 && isPrimaryChange && !newPrimaryFound)) {
            Map<String, Object> recipient = new Map<String, Object>();
            String censusId = (String)(censusMemberList[0].vlocity_ins__CensusId__c);          
            String interKey = 'interKey-' + recipients.size();
            String templateRole = 'Primary';
            
            vlocity_ins__GroupCensus__c guardian = [
                SELECT ARC_GuardianAccount__r.PersonContactId, ARC_GuardianAccount__r.PersonEmail, ARC_GuardianAccount__r.Name
                FROM vlocity_ins__GroupCensus__c 
                WHERE Id = :censusId
            ];

            recipient.put('interKey', interKey);
            recipient.put('routingOrder', null);
            recipient.put('templateRole', templateRole);
            recipient.put('signerEmail', guardian.ARC_GuardianAccount__r.PersonEmail);
            recipient.put('signerName', guardian.ARC_GuardianAccount__r.Name);
            recipient.put('memberOrContactId', guardian.ARC_GuardianAccount__r.PersonContactId);
            recipient.put('isGuardian', true);

            recipients.add(recipient);
        }
        if (isPrimaryChange && !oldPrimaryFound) {
            if (oldPrimary != null && oldPrimary.ARC_Age__c >= 18) {
                Map<String, Object> recipient = new Map<String, Object>();
                String censusId = (String)(censusMemberList[0].vlocity_ins__CensusId__c);          
                String interKey = 'interKey-' + recipients.size();
                String templateRole = 'Dependent1';

                recipient.put('interKey', interKey);
                recipient.put('routingOrder', null);
                recipient.put('templateRole', templateRole);
                recipient.put('signerEmail', oldPrimary.vlocity_ins__Email__c);
                recipient.put('signerName', oldPrimary.Name);
                recipient.put('memberOrContactId', oldPrimary.Id);
                recipient.put('isGuardian', false);

                recipients.add(recipient);
            } else if (oldPrimary != null && oldPrimary.ARC_Age__c < 18 && newPrimary != null && newPrimary.ARC_Age__c >= 18) {
                Map<String, Object> recipient = new Map<String, Object>();
                String censusId = (String)(censusMemberList[0].vlocity_ins__CensusId__c);          
                String interKey = 'interKey-' + recipients.size();
                String templateRole = 'Dependent1';
                
                vlocity_ins__GroupCensus__c guardian = [
                    SELECT ARC_GuardianAccount__r.PersonContactId, ARC_GuardianAccount__r.PersonEmail, ARC_GuardianAccount__r.Name
                    FROM vlocity_ins__GroupCensus__c 
                    WHERE Id = :censusId
                ];
    
                recipient.put('interKey', interKey);
                recipient.put('routingOrder', null);
                recipient.put('templateRole', templateRole);
                recipient.put('signerEmail', guardian.ARC_GuardianAccount__r.PersonEmail);
                recipient.put('signerName', guardian.ARC_GuardianAccount__r.Name);
                recipient.put('memberOrContactId', guardian.ARC_GuardianAccount__r.PersonContactId);
                recipient.put('isGuardian', true);
    
                recipients.add(recipient);
            }
        }

        outputMap.put('recipients', recipients);
    } 

    /*******************************************************************
    * @MethodName         :   generateQueryForTemplateSettings
    * @Description        :   Returns template id from vlocity_ins__VlocityDocuSignTemplate__c (custom setting) according to the reasons and dependents involved in the contract 
    ********************************************************************/
    global void getTemplateId (Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {    
        String reasons = (String)inputMap.get('reasons'); 
        Integer dependents = (Integer)inputMap.get('dependents');
        Boolean childOnly = (Boolean)inputMap.get('childOnly');
        String state = (String)inputMap.get('state');
        Boolean isLegacy;
        String medicalPlan = inputMap.containsKey('medicalPlan') ? (String)inputMap.get('medicalPlan') : '';
        if (inputMap.containsKey('isLegacy')) {
            isLegacy = (Boolean)inputMap.get('isLegacy');
        }

        // get name from custom setting
        String queryStr = generateQueryForTemplateSettings(reasons, dependents, childOnly, state, medicalPlan);
        System.debug('query string: ' + queryStr);
        ARC_DocuSignTemplates__c templateSettings = Database.query(queryStr);
        System.debug('template settings: ' + templateSettings);
        String templateNameStr = templateSettings.ARC_Template_Name__c;
        if (isLegacy == true) {
            templateNameStr = state == 'CA' ? 'WeShare Legacy Membership Application CA' : 'WeShare Legacy Membership Application';
        } 
      
        System.debug('templateNameStr: ' + templateNameStr);

        // get template identifier from vlocity record.-
        vlocity_ins__VlocityDocuSignTemplate__c template = [SELECT id,name,vlocity_ins__templateidentifier__c FROM vlocity_ins__VlocityDocuSignTemplate__c WHERE name = :templateNameStr ORDER BY LastModifiedDate DESC LIMIT 1];
        Map<String, Object> templateData = new Map<String, Object>();
        Map<String, String> templateMap = new Map<String, String>();
        templateMap.put('Id', template.Id);
        templateMap.put('Name', template.name);
        templateMap.put('vlocity_ins__TemplateIdentifier__c', template.vlocity_ins__templateidentifier__c);
        templateData.put('Template', templateMap);
        templateData.put('Settings', templateSettings);

        outputMap.put('templateData', templateData);
    }
    /*******************************************************************
    * @MethodName         :   generateQueryForTemplateSettings
    * @Description        :   Returns query string for docusing template
    ********************************************************************/
    private static String generateQueryForTemplateSettings(String reasons, Integer dependents, Boolean childOnly, String state, String medicalPlan) {
        String queryStr = '';
        String reasonConditons = '';
        List<String> reasonsList = reasons.split(';');
        Boolean hasProgramChangeReason = reasonsList.contains('Add Member') || reasonsList.contains('Remove Member') || reasonsList.contains('Program Upgrade') || reasonsList.contains('Program Downgrade') || reasonsList.contains('Ancillary Change') || reasonsList.contains('Add Existing Member') || reasonsList.contains('Primary change');
        System.debug(reasonsList);
        Boolean isCancellation = reasons == 'Cancellation';
        
        System.debug('reasons list: ' + reasonsList);

        if (medicalPlan == 'WeShare Legacy') {
            queryStr = state == 'CA' ? 'SELECT ARC_Template_Name__c, ARC_DRTransform__c FROM ARC_DocuSignTemplates__c WHERE ARC_Template_Name__c = \'WeShare Legacy Membership Application CA\'' : 'SELECT ARC_Template_Name__c, ARC_DRTransform__c FROM ARC_DocuSignTemplates__c WHERE ARC_Template_Name__c = \'WeShare Legacy Membership Application\'';
        } else {
            for (String reason : reasonsList) {
                reasonConditons += 'ARC_Contract_Reasons__c LIKE \'%'+ reason +'%\' ';
                if (reasonsList.indexOf(reason) != reasonsList.size() -1) {
                    reasonConditons += 'OR ';
                }
            }
            queryStr = 'SELECT ARC_Template_Name__c, ARC_DRTransform__c FROM ARC_DocuSignTemplates__c WHERE (' + reasonConditons + ') ';

            if (hasProgramChangeReason) {
                queryStr += 'AND Has_No_Priority__c != true';
            }

            if (!isCancellation) {
                queryStr += ' AND ARC_Min_Dependents__c <= ' + dependents;
                queryStr += ' AND ARC_Max_Dependents__c >= ' + dependents;
                for (String reason : reasonsList) {
                    if (reason == 'New Application' || reason == 'Spin Off' || reason == 'Upgraded Spin Off') {
                        queryStr += ' AND ARC_ChildOnly__c = ' + childOnly;
                        break;
                    }
                }
                if (state == 'CA') queryStr += ' AND ARC_State__c =  \'CA\'';
                if (reasons.contains('New Application')) {
                    queryStr += medicalPlan.contains('Access') ? ' AND ARC_PlanType__c = \'Access\'' : medicalPlan.contains('Legacy') ? ' AND ARC_PlanType__c = \'Legacy\'' : ' AND ARC_PlanType__c = \'WeShare\'';
                }
                queryStr += ' ORDER BY ARC_Template_Name__c ASC LIMIT 1';
            }
        }        
        System.debug('query: ' + queryStr);
        return queryStr;
    }
    /*******************************************************************
    * @MethodName         :   isPublicGroupMember
    * @Description        :   Method returns true if the member provided (member's Id) is part of the public groupName (Api name) provided
    ********************************************************************/
    private static void isPublicGroupMember(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        String userRoleId = (String)inputMap.get('UserRoleId');
        String groupApiName = (String)inputMap.get('GroupName');

        List<GroupMember> publicGroupRolesAndUsers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId IN (SELECT Id FROM Group WHERE DeveloperName =: groupApiName)];
        Id userGroupId = [SELECT Id FROM Group WHERE relatedId =: userRoleId AND Type = 'Role' LIMIT 1].Id;

        for (GroupMember groupMember : publicGroupRolesAndUsers) {
            if (groupMember.UserOrGroupId == userGroupId) {
                outputMap.put('belongsInGroup', true);
                return;
            }
        }
        outputMap.put('belongsInGroup', false);
    }

    /*******************************************************************
    * @MethodName         :   filterMembersById
    * @Description        :   For redend contract, when contract reason is just Add Member, envelope needs to show only the new member. Method recieves list of pre-filtered members from the current program and a list containing ids from the members on the previous contract.
                                returns the list of the members on the new contract that are not in the previous contract as a List<Map<>>-  
    ********************************************************************/
    private static void filterMembersById(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        //List<Object> oldMemberIds = (List<Object>)inputMap.get('OldMembers');
        String contractId = (String)inputMap.get('OldContractId');
        List<Object> filteredMembers = (List<Object>)inputMap.get('FilteredMembers');
        List<Object> returnfilteredMembers = new List<Object>();
        Set<Id> oldMemberIds = new Set<Id>();
        for (vlocity_ins__GroupCensusMember__c cm : [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE Id IN (SELECT vlocity_ins__GroupCensusMemberId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId ) ]) {
            oldMemberIds.add(cm.Id);
        }
        for (Integer i = 0; i < filteredMembers.size(); i++) {
            Map<String, Object> memb = (Map<String, Object>)filteredMembers[i];
            Id filteredMemberId = (Id)memb.get('Id');
            if (!oldMemberIds.contains(filteredMemberId)) {
                returnfilteredMembers.add(filteredMembers[i]);
            }
        }
        outputMap.put('filteredNewMembers', returnfilteredMembers);
    }

    private Map<String,String> getPastConditionIndex() {
        List<String> pastConditonList = new List<String>{
            'Alcohol Abuse',
            'ALS',
            'Alzheimer’s Disease',
            'Abdominal Aortic Aneurysm',
            'Aneurysm, Cerebral',
            'Autism Spectrum Disorders',
            'Bipolar with 2 or more current medications',
            'Cerebral Palsy',
            'Chronic Obstructive Pulmonary Disease (COPD)',
            'Chronic Kidney Disease, stage 3b, 4 or 5',
            'Cystic Fibrosis',
            'Dementia',
            'Diabetes, Type I',
            'Diabetes, Type 2 when taking 2 heart medications, or have kidney/liver disease',
            'Down’s Syndrome',
            'Ectasia',
            'Emphysema',
            'Fragile X Syndrome',
            'Fibromyalgia (w/ treatment)',
            'Hepatitis (Chronic Viral B & C)',
            'HIV/AIDS',
            'Lupus',
            'Macular Degeneration (wet or dry)',
            'Marfan’s Syndrome',
            'Morbid Obesity (BMI > 40)',
            'Multiple Sclerosis',
            'Muscular Dystrophy',
            'Paralysis',
            'Parkinson’s Disease',
            'Rheumatoid Arthritis w/ biologic treatment',
            'Schizophrenia with 2 or more current medications',
            'Sickle-Cell Disease',
            'Sjogren Syndrome',
            'Spina Bifida',
            'Systemic Lupus Erythematosus',
            'Typhoid',
            'Underweight (BMI <15)',
            'Inpatient Psychiatric Treatment within past 5 years',
            'Treatment with Naloxone, Suboxone, Methadone or any other medication to treat addiction within the past 5 years'
        };

        Map<String,String> pastConditionIndex = new Map<String,String>();
        for (Integer i = 0; i < pastConditonList.size(); i++) {
            pastConditionIndex.put(pastConditonList[i],String.valueOf(i + 1));
        }
        return pastConditionIndex;
    }
}