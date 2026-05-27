global without sharing class ARC_DocuSignResendController implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map <String, Object> inputMap, Map<String, Object> outputMap, Map <String, Object> options) {
        switch on methodName {
            when 'getAllRecipientList' {
                getAllRecipientList(inputMap, outputMap, options);
            }
            when 'getHipaaRecipientList' {
                getHipaaRecipientList(inputMap, outputMap, options);
            }
            when 'getDocuSignData' {
                getDocuSignData(inputMap, outputMap, options);
            }
            when 'getNewEnvelopeId' {
                getNewEnvelopeId(inputMap, outputMap, options);
            }
            when 'voidOldEnvelope' {
                voidOldEnvelope(inputMap, outputMap, options);
            }
        }
        return true;
    }

    private static List<String> pcReasonsList = new List<String>{'Program Upgrade', 'Program Downgrade', 'Add Member', 'Remove Member', 'Add Ancillary Product', 'Remove Ancillary', 'Add Existing Member', 'Primary Change', 'Relationship to Primary Change', 'State Change', 'Effective Date Change', 'Date of Birth Change'};
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
    private static Boolean isProgramChange = false;
    private static Boolean isPrimaryChange = false;
    private static Boolean isAddMember = false;
    private static List<Map<String,Object>> addMemberList = new List<Map<String,Object>>();
    private static Boolean allNeedToSign = true;
    private static Map<String,Object> oldPrimaryMap = new Map<String,Object>();
    private static Boolean isChildFamily = false;
    private static Integer dependentCount;
    private static String medicalProgram;
    private static String primaryState;
    private static List<String> templateNameList = new List<String>();

    public static void getHipaaRecipientList(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        String contractId = (String)inputMap.get('contractId');
        
        Contract contract = [SELECT Id, vlocity_ins__EnrollmentCensusId__c FROM Contract WHERE Id = :contractId LIMIT 1];

        List<ARC_HipaaAuthorization__c> hipaaList = [
            SELECT Id, ARC_AuthorizedMember__c, ARC_AuthorizedMember__r.Name, ARC_AuthorizedMember__r.vlocity_ins__Email__c, ARC_AuthorizedMember__r.ARC_Phone__c, ARC_AuthorizedMember__r.ARC_Age__c, 
                ARC_ExternalPersonAuthorized__c, ARC_ExternalPersonAuthorized__r.AccountId, ARC_ExternalPersonAuthorized__r.Email, ARC_ExternalPersonAuthorized__r.Phone, ARC_ExternalPersonAuthorized__r.Name, ARC_ExternalPersonAuthorized__r.Account.ARC_GuardianRelationshipToChild__c
            FROM ARC_HipaaAuthorization__c
            WHERE ARC_Census__c = :contract.vlocity_ins__EnrollmentCensusId__c
        ];

        List<ARC_ContractParticipant__c> contPartList = [
            SELECT Id, ARC_PersonAccount__c, ARC_PersonAccount__r.Census_Member__c, Name, ARC_PersonAccount__r.PersonEmail, ARC_Relationship__c, ARC_PersonAccount__r.Phone, ARC_PersonAccount__r.vlocity_ins__Age__pc
            FROM ARC_ContractParticipant__c 
            WHERE ARC_Contract__c = :contractId
        ];

        List<Map<String,Object>> recipientList = new List<Map<String,Object>>();
        for (ARC_HipaaAuthorization__c hipaa : hipaaList) {
            if (hipaa.ARC_AuthorizedMember__c != null) {
                ARC_ContractParticipant__c cp = findContractParticipantFromHipaa(hipaa, contPartList);
                if (cp != null) {
                    if (cp.ARC_PersonAccount__r.vlocity_ins__Age__pc < 18 || cp.ARC_PersonAccount__r.PersonEmail == null) continue;
                    Map<String,Object> cpMap = new Map<String,Object>{
                        'recipientId' => String.valueOf(cp.ARC_PersonAccount__r.Census_Member__c),
                        'recipientName' => String.valueOf(cp.Name),
                        'recipientEmail' => String.valueOf(cp.ARC_PersonAccount__r.PersonEmail),
                        'recipientRole' => String.valueOf(cp.ARC_Relationship__c),
                        'recipientPhone' => String.valueOf(cp.ARC_PersonAccount__r.Phone),
                        'recipientAge' => Integer.valueOf(cp.ARC_PersonAccount__r.vlocity_ins__Age__pc)
                    };
                    recipientList.add(cpMap);
                } else {
                    if (hipaa.ARC_AuthorizedMember__r.vlocity_ins__Email__c == null) continue;
                    Map<String,Object> hipaaMap = new Map<String,Object>{
                        'recipientId' => String.valueOf(hipaa.ARC_AuthorizedMember__c),
                        'recipientName' => String.valueOf(hipaa.ARC_AuthorizedMember__r.Name),
                        'recipientEmail' => String.valueOf(hipaa.ARC_AuthorizedMember__r.vlocity_ins__Email__c),
                        'recipientRole' => 'Other',
                        'recipientPhone' => String.valueOf(hipaa.ARC_AuthorizedMember__r.ARC_Phone__c),
                        'recipientAge' => Integer.valueOf(hipaa.ARC_AuthorizedMember__r.ARC_Age__c)
                    };
                    recipientList.add(hipaaMap);
                }
            } else if (hipaa.ARC_ExternalPersonAuthorized__c != null) {
                if (hipaa.ARC_ExternalPersonAuthorized__r.Email == null) continue;
                // Guardian defined by role
                String role = String.valueOf(hipaa.ARC_ExternalPersonAuthorized__r.Account.ARC_GuardianRelationshipToChild__c);

                Map<String,Object> externalMap = new Map<String,Object>{
                    'recipientId' => role != null && role != '' ? String.valueOf(hipaa.ARC_ExternalPersonAuthorized__r.AccountId) : String.valueOf(hipaa.ARC_ExternalPersonAuthorized__c),
                    'recipientName' => String.valueOf(hipaa.ARC_ExternalPersonAuthorized__r.Name),
                    'recipientEmail' => String.valueOf(hipaa.ARC_ExternalPersonAuthorized__r.Email),
                    'recipientRole' => role != null && role != '' ? role : 'Other',
                    'recipientPhone' => String.valueOf(hipaa.ARC_ExternalPersonAuthorized__r.Phone)
                };
                recipientList.add(externalMap);
            }
        }
        outputMap.put('recipients', recipientList);
    }

    private static ARC_ContractParticipant__c findContractParticipantFromHipaa(ARC_HipaaAuthorization__c hipaa, List<ARC_ContractParticipant__c> contPartList) {
        ARC_ContractParticipant__c output_cp;
        for (ARC_ContractParticipant__c cp : contPartList) {
            if (cp.ARC_PersonAccount__r.Census_Member__c == hipaa.ARC_AuthorizedMember__c) {
                output_cp = cp;
                break;
            }
        }
        return output_cp;
    }

    public static void getAllRecipientList(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        String contractId = (String)inputMap.get('contractId');
        
        List<ARC_ContractParticipant__c> contPartList = [
            SELECT Id, ARC_PersonAccount__c, ARC_PersonAccount__r.Census_Member__c, Name, ARC_PersonAccount__r.PersonEmail, ARC_Relationship__c, ARC_PersonAccount__r.Phone, ARC_PersonAccount__r.vlocity_ins__Age__pc, ARC_Contract__r.ARC_Guardian__c, ARC_Contract__r.ARC_Guardian__r.Name, ARC_Contract__r.ARC_Guardian__r.PersonEmail, ARC_Contract__r.ARC_Guardian__r.Phone, ARC_Contract__r.ARC_Guardian__r.ARC_GuardianRelationshipToChild__c
            FROM ARC_ContractParticipant__c 
            WHERE ARC_Contract__c = :contractId
        ];

        List<Map<String,Object>> recipientList = new List<Map<String,Object>>();
        for (ARC_ContractParticipant__c cp : contPartList) {
            Integer memberAge = Integer.valueOf(cp.ARC_PersonAccount__r.vlocity_ins__Age__pc);
            String memberRelationship = String.valueOf(cp.ARC_Relationship__c);
            if (memberAge >= 18) {
                Map<String,Object> cpMap = new Map<String,Object>{
                    'recipientId' => String.valueOf(cp.ARC_PersonAccount__r.Census_Member__c),
                    'recipientName' => String.valueOf(cp.Name),
                    'recipientEmail' => String.valueOf(cp.ARC_PersonAccount__r.PersonEmail),
                    'recipientRole' => String.valueOf(cp.ARC_Relationship__c),
                    'recipientPhone' => String.valueOf(cp.ARC_PersonAccount__r.Phone),
                    'recipientAge' => Integer.valueOf(cp.ARC_PersonAccount__r.vlocity_ins__Age__pc)
                };
                recipientList.add(cpMap);
            }
            if (memberAge < 18 && memberRelationship == 'Primary' && cp.ARC_Contract__r.ARC_Guardian__c != null) {
                String guardianRole = String.valueOf(cp.ARC_Contract__r.ARC_Guardian__r.ARC_GuardianRelationshipToChild__c);
                Map<String,Object> guardianMap = new Map<String,Object>{
                    'recipientId' => String.valueOf(cp.ARC_Contract__r.ARC_Guardian__c),
                    'recipientName' => String.valueOf(cp.ARC_Contract__r.ARC_Guardian__r.Name),
                    'recipientEmail' => String.valueOf(cp.ARC_Contract__r.ARC_Guardian__r.PersonEmail),
                    'recipientRole' => guardianRole != null && guardianRole != '' ? guardianRole : 'Legal Guardian',
                    'recipientPhone' => String.valueOf(cp.ARC_Contract__r.ARC_Guardian__r.Phone)
                };
                recipientList.add(guardianMap);
            }
        }

        outputMap.put('allRecipients', recipientList);
    }

    public static void getDocuSignData(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        String contractId = (String)inputMap.get('contractId');
        Map<String,Object> selectedRecipient = (Map<String,Object>)inputMap.get('selectedRecipient');
        List<Object> allRecipients = (List<Object>)inputMap.get('allRecipients');
        outputMap.put('contractId', contractId);
        outputMap.put('Selected Recipient', selectedRecipient);
        outputMap.put('allRecipients', allRecipients);

        // Get info from Contract
        Contract cont = [SELECT Id, 
                Status,
                ARC_EffectiveDate__c,
                vlocity_ins__EnrollmentCensusId__c, 
                ARC_Guardian__c,
                ARC_Guardian__r.Name,
                ARC_Guardian__r.FirstName,
                ARC_Guardian__r.vlocity_ins__MiddleName__pc,
                ARC_Guardian__r.LastName,
                ARC_Guardian__r.ARC_SocialSecurityNumber__pc ,
                ARC_Guardian__r.ARC_SocialSecurityNumber__c ,
                ARC_Guardian__r.BillingStreet,
                ARC_Guardian__r.ARC_BillingAptUnit__c,
                ARC_Guardian__r.BillingCity,
                ARC_Guardian__r.BillingState,
                ARC_Guardian__r.BillingPostalCode,
                ARC_Guardian__r.Phone,
                ARC_Guardian__r.PersonEmail,
                ARC_Guardian__r.PersonBirthdate,   
                ARC_Guardian__r.PersonGender,
                ARC_Guardian__r.ARC_GuardianRelationshipToChild__c, 
                ARC_ContractReason__c, 
                vlocity_ins__ExpiredContractId__c,  
                vlocity_ins__ExpiredContractId__r.ARC_CancellationReason__c,
                vlocity_ins__ExpiredContractId__r.vlocity_ins__EnrollmentCensusId__c,
                vlocity_ins__ExpiredContractId__r.Status, 
                vlocity_ins__ExpiredContractId__r.ARC_Guardian__r.Name, 
                vlocity_ins__ExpiredContractId__r.ARC_Guardian__r.PersonEmail, 
                vlocity_ins__ExpiredContractId__r.ARC_Guardian__r.Phone, 
                vlocity_ins__ExpiredContractId__r.ARC_Guardian__r.ARC_GuardianRelationshipToChild__c, 
                ARC_MedicalPlan__r.Name, 
                ARC_PrimaryAddress__StateCode__s,
                vlocity_ins__LastDocuSignEnvelopeId__c,
                ARC_TotalPrice__c,
                ARC_RecurringMonthlyOrder__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Method__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Amount__c, 
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Name__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Type__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Name__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Number__c, 
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Routing_Number__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Credit_Card_Name__c, 
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Type__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Last_4__c, 
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Month_Indicator__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Year_Indicator__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c,
                ARC_AppFeeOrder__c, 
                ARC_AppFeeOrder__r.ChargentOrders__Total__c,
                ARC_AppFeeOrder__r.ChargentOrders__Payment_Method__c,
                ARC_AppFeeOrder__r.ChargentOrders__Bank_Name__c,
                ARC_AppFeeOrder__r.ChargentOrders__Bank_Account_Type__c,
                ARC_AppFeeOrder__r.ChargentOrders__Bank_Account_Name__c,
                ARC_AppFeeOrder__r.ChargentOrders__Bank_Account_Number__c, 
                ARC_AppFeeOrder__r.ChargentOrders__Bank_Routing_Number__c,
                ARC_AppFeeOrder__r.ChargentOrders__Credit_Card_Name__c, 
                ARC_AppFeeOrder__r.ChargentOrders__Card_Type__c,
                ARC_AppFeeOrder__r.ChargentOrders__Card_Last_4__c, 
                ARC_AppFeeOrder__r.ChargentOrders__Card_Month_Indicator__c,
                ARC_AppFeeOrder__r.ChargentOrders__Card_Year_Indicator__c,
                ARC_AppFeeOrder__r.ChargentOrders__Billing_Address__c,
                ARC_AppFeeOrder__r.ChargentOrders__Billing_City__c,
                ARC_AppFeeOrder__r.ChargentOrders__Billing_State__c,
                ARC_AppFeeOrder__r.ChargentOrders__Billing_Zip_Postal__c,
                (SELECT Id,
                    ARC_Relationship__c,
                    ARC_PersonAccount__r.Census_Member__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_ActiveMember__c,
                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_MiddleInitial__c,
                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__SocialSecurityNumber__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_Phone__c,
                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Email__c,
                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Birthdate__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_Age__c,
                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Gender__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_Height__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_Weight__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_Smoker__c,
                    ARC_PersonAccount__r.Census_Member__r.ARC_Relationship__c,
                    ARC_PersonAccount__r.Medicare_ID__c,
                    ARC_PersonAccount__r.Medicare_Part_A_Effective_Date__c,
                    ARC_PersonAccount__r.Medicare_Part_B_Effective_Date__c,
                    ARC_PersonAccount__r.Medicare_Part_D_Effective_Date__c
                FROM Contract_Participants__r)
            FROM Contract 
            WHERE Id = :contractId 
            LIMIT 1
        ];

        // Get general info from contract
        String censusId = cont.vlocity_ins__EnrollmentCensusId__c;
        String medicalPlanName = String.valueOf(cont.ARC_MedicalPlan__r.Name);
        dependentCount = Integer.valueOf(inputMap.get('dependentCount'));
        // primaryState = String.valueOf(cont.ARC_PrimaryAddress__StateCode__s);
        medicalProgram = String.valueOf(cont.ARC_MedicalPlan__r.Name);
        isChildFamily = cont.ARC_Guardian__c != null ? true : false;
        String contractReason = cont.ARC_ContractReason__c;
        List<String> contReasonList = contractReason.split(';');
        outputMap.put('envelopeId', cont.vlocity_ins__LastDocuSignEnvelopeId__c);

        outputMap.put('Contract Reason List: ', contReasonList);

        // Get Active or Expiraed Contract Id
        List<Contract> activatedContractList = [SELECT Id, Status FROM Contract WHERE vlocity_ins__EnrollmentCensusId__c = :censusId AND Status = 'Activated' LIMIT 1];
        outputMap.put('Activated Contract', activatedContractList);
        String eligibleContractId = activatedContractList != null && !activatedContractList.isEmpty() ? activatedContractList[0].Id : cont.vlocity_ins__ExpiredContractId__c;

        // Validate if it is a Program Change and get old primary if it is a Primary Change
        for (String reason : contReasonList) {
            // Validate contract reasons contain a PC reason AND not contain 'Spin Off' OR contain 'Spin Off' but it is a PC from a Spin Off contract
            if (pcReasonsList.contains(reason) && (!contReasonList.contains('Spin Off') || (contReasonList.contains('Spin Off') && cont.vlocity_ins__ExpiredContractId__c != null && cont.vlocity_ins__ExpiredContractId__r.Status == 'Voided' && cont.vlocity_ins__EnrollmentCensusId__c == cont.vlocity_ins__ExpiredContractId__r.vlocity_ins__EnrollmentCensusId__c))) {
                isProgramChange = true;
                if (reason == 'Primary Change' && !contReasonList.contains('Spin Off')) isPrimaryChange = true;
                if (reason == 'Add Member' || reason == 'Add Existing Member') isAddMember = true;
            }
        }
        if (!contReasonList.contains('Spin Off') && !contReasonList.contains('New Application')) allNeedToSign = false;
        outputMap.put('isPrimaryChange', isPrimaryChange);
        outputMap.put('isProgramChange', isProgramChange);

        // Get old primary is primary change and guardin info if old primary is not +18
        if (isPrimaryChange && cont.Status != 'Activated') {
            List<vlocity_ins__GroupCensusMember__c> censusMemberList = [SELECT Id, ARC_Relationship__c, vlocity_ins__Email__c, ARC_Phone__c, Name, vlocity_ins__ContactId__r.Account.vlocity_ins__Age__pc FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :cont.vlocity_ins__EnrollmentCensusId__c AND ARC_ActiveMember__c = true] ;
            for (vlocity_ins__GroupCensusMember__c cm : censusMemberList) {
                Integer memberAge = Integer.valueOf(cm.vlocity_ins__ContactId__r.Account.vlocity_ins__Age__pc);
                if (cm.ARC_Relationship__c == 'Primary') {
                    oldPrimaryMap.put('recipientId', memberAge >= 18 ? cm.Id : cont.vlocity_ins__ExpiredContractId__r.ARC_Guardian__c);
                    oldPrimaryMap.put('recipientName', memberAge >= 18 ? cm.Name : cont.vlocity_ins__ExpiredContractId__r.ARC_Guardian__r.Name);
                    oldPrimaryMap.put('recipientRole', memberAge >= 18 ? cm.ARC_Relationship__c : 'Guardian');
                    oldPrimaryMap.put('recipientEmail', memberAge >= 18 ? cm.vlocity_ins__Email__c : cont.vlocity_ins__ExpiredContractId__r.ARC_Guardian__r.PersonEmail);
                    oldPrimaryMap.put('recipientPhone', memberAge >= 18 ? cm.ARC_Phone__c : cont.vlocity_ins__ExpiredContractId__r.ARC_Guardian__r.Phone);
                }
            }
        }

        // Get the list of Census Members IDs (Need to query because if it is a Spin Off contract, the CM linked to the Contract Participant are the old Census Members)
        List<Id> cmIdList = new List<Id>();
        Map<Id, Id> newToOldCMId = new Map<Id, Id>();
        for (vlocity_ins__GroupCensusMember__c cm : [SELECT Id, ARC_OldCensusMember__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :censusId]) {
            cmIdList.add(cm.Id);
            if (cm.ARC_OldCensusMember__c != null)  newToOldCMId.put(cm.Id, cm.ARC_OldCensusMember__c);
        }

        //Build member list with formatted keys and add cm Id to list
        // List<Id> cmIdList = new List<Id>();
        Map<String,Object> memberListMap = new Map<String,Object>();
        for (ARC_ContractParticipant__c cp : cont.Contract_Participants__r) {
            // cmIdList.add(cp.ARC_PersonAccount__r.Census_Member__c);
            Map<String,Object> memberMap = formatMemberMap(cp);
            if (memberMap.get('Relationship') == 'Primary') primaryState = (String)memberMap.get('State');
            memberListMap.put(cp.ARC_PersonAccount__r.Census_Member__c, memberMap);
            if (cp.ARC_PersonAccount__r.Census_Member__r.ARC_ActiveMember__c == false) addMemberList.add(memberMap);
            }
        // Get old/active members ONLY if it is a PC
        Map<String,Object> oldMemberListMap = isProgramChange ? getOldMemberList(eligibleContractId) : null;
        Map<String,Object> membersMap = new Map<String,Object>{
            'newMembers' => memberListMap,
            'oldMembers' => oldMemberListMap
        };
        outputMap.put('membersMap', membersMap);

        // Build guardian map if it is child family
        Map<String,Object> guardianMap = new Map<String,Object>();
        if (isChildFamily) {
            guardianMap.put('FirstName', String.valueOf(cont.ARC_Guardian__r.FirstName));
            guardianMap.put('MI', String.valueOf(cont.ARC_Guardian__r.vlocity_ins__MiddleName__pc));
            guardianMap.put('LastName', String.valueOf(cont.ARC_Guardian__r.LastName));
            String guardianSSN;
            if(cont.ARC_Guardian__r.ARC_SocialSecurityNumber__pc != null) {
                guardianSSN = String.valueOf(cont.ARC_Guardian__r.ARC_SocialSecurityNumber__pc);
                if(!Test.isRunningTest()) guardianMap.put('SSN', 'XXX-XX-' + guardianSSN.right(4));   
            }
            if(cont.ARC_Guardian__r.ARC_SocialSecurityNumber__c != null) {
                guardianSSN = String.valueOf(cont.ARC_Guardian__r.ARC_SocialSecurityNumber__c);
                if(!Test.isRunningTest()) guardianMap.put('SSN', 'XXX-XX-' + guardianSSN.right(4));   
            }
            guardianMap.put('Address', String.valueOf(cont.ARC_Guardian__r.BillingStreet));
            guardianMap.put('Unit', String.valueOf(cont.ARC_Guardian__r.ARC_BillingAptUnit__c));
            guardianMap.put('City', String.valueOf(cont.ARC_Guardian__r.BillingCity));
            guardianMap.put('State', String.valueOf(cont.ARC_Guardian__r.BillingState));
            guardianMap.put('ZipCode', String.valueOf(cont.ARC_Guardian__r.BillingPostalCode));
            guardianMap.put('Phone', String.valueOf(cont.ARC_Guardian__r.Phone));
            guardianMap.put('Email', String.valueOf(cont.ARC_Guardian__r.PersonEmail));
            guardianMap.put('DOB', String.valueOf(cont.ARC_Guardian__r.PersonBirthdate));
            guardianMap.put('Male', cont.ARC_Guardian__r.PersonGender == 'Male' ? true : false);
            guardianMap.put('Female', cont.ARC_Guardian__r.PersonGender == 'Female' ? true : false);
            guardianMap.put('GuardianRelationshipToChild', String.valueOf(cont.ARC_Guardian__r.ARC_GuardianRelationshipToChild__c));    
        }
        outputMap.put('guardianInfo', guardianMap);

        // Get all Medical Questions grouped by Member
        outputMap.put('CM List: ' + cmIdList.size(), 'Members : ' + String.join(cmIdList, ','));
        Map<String,Object> memberToMedicalQuestionsMap = getMemberMedicalQuestions(cmIdList);
        for (String newMemberId : memberToMedicalQuestionsMap.keySet()) {
            if (newToOldCMId.containsKey(newMemberId)) {
                String oldMemberId = newToOldCMId.get(newMemberId);
                memberToMedicalQuestionsMap.put(oldMemberId, memberToMedicalQuestionsMap.get(newMemberId));
                memberToMedicalQuestionsMap.remove(newMemberId);
            }
        }
        outputMap.put('medicalQuestionsMap', memberToMedicalQuestionsMap);

        // Get program map
        Map<String,Object> programsMap = getOldAndNewProgramsMap(isProgramChange, contractId, eligibleContractId);
        outputMap.put('programsMap', programsMap);

        // Get payment info
        Map<String,Object> paymentInfo = getPaymentInfoMap(cont);
        outputMap.put('paymentInfo', paymentInfo);

        // Get Beneficiaries Map if it is a Premier Program
        Map<String,Object> beneficiariesMap = new Map<String,Object>();
        outputMap.put('Medical Plan Name', medicalPlanName);
        if (medicalPlanName.contains('Premier')) {
            beneficiariesMap = getBeneficiariesMap(contractId);
        }
         outputMap.put('Beneficiaries', beneficiariesMap);

        // Get hipaa name list
        List<ARC_HipaaAuthorization__c> hipaa = [SELECT Id, Name FROM ARC_HipaaAuthorization__c WHERE ARC_Census__c = :censusId];
        List<String> hipaaNameList = new List<String>();
        if (hipaa != null && !hipaa.isEmpty()) {
            for (ARC_HipaaAuthorization__c h : hipaa) {
                hipaaNameList.add(String.valueOf(h.Name));
            }
        }

        // Build the subject for the email
        String envelopeSubject = isProgramChange ? 'Please DocuSign: UHSM Program Change' : contReasonList.contains('Spin Off') ? 'Please DocuSign: UHSM Spin Off' : 'Please DocuSign: WeShare healthcare by UHSM Application';
        outputMap.put('subject', envelopeSubject);
        
        // Build input and call the method to get the list of signers
        Map<String,Object> signerListInputMap = new Map<String,Object>{
            'allRecipients' => allRecipients,
            'selectedRecipient' => selectedRecipient
        };
        List<Map<String,Object>> signerList = getSignerList(signerListInputMap);

        // Call method to get the list of templates to use
        List<String> templatesIdList = getTemplatesIdList();

        // Build input and call method to get the tabs map
        Map<String,Object> getDocuSignTabsInputMap = new Map<String,Object>{
            'membersMap' => membersMap,
            'programsMap' => programsMap,
            'medicalQuestionsMap' => memberToMedicalQuestionsMap,
            'paymentInfo' => paymentInfo,
            'guardianInfo' => guardianMap,
            'isChildFamily' => isChildFamily,
            'isProgramChange' => isProgramChange,
            'contractReasons' => contractReason,
            'effectiveDate' => String.valueOf(cont.ARC_EffectiveDate__c),
            'beneficiariesMap' => beneficiariesMap,
            'hipaa' => hipaaNameList,
            'signerList' => signerList
        };
        Map<String,Object> docuSignTabs = getDocuSignTabs(getDocuSignTabsInputMap);

        outputMap.put('signerList', signerList);
        outputMap.put('templateIdList', templatesIdList);
        outputMap.put('templateNameList', templateNameList); // JUST FOR TEST
        outputMap.put('docuSignTabs', docuSignTabs);
    }

    private static List<Map<String,Object>> getSignerList(Map<String,Object> input) {
        List<Map<String,Object>> signerList = new List<Map<String,Object>>();
        List<Object> allRecipients = (List<Object>)input.get('allRecipients');

        Integer signerDependentCount = 0;

        if (allNeedToSign) {
            for (Integer i = 1; i <= allRecipients.size(); i++) {
                Map<String,Object> signerMap = new Map<String,Object>();
                Map<String,Object> memberMap = (Map<String,Object>)allRecipients[i-1];
                String memberPhone = (String)memberMap.get('recipientPhone');
                String memberRole = (String)memberMap.get('recipientRole');
                if (memberRole != 'Primary' && memberRole != 'Spouse') signerDependentCount++;
                signerMap.put('recipientId', (String)memberMap.get('recipientId'));
                signerMap.put('name', (String)memberMap.get('recipientName'));
                signerMap.put('email', (String)memberMap.get('recipientEmail'));
                signerMap.put('deliveryMethod', 'Email');
                signerMap.put('roleName', isChildFamily ? 'Primary' : memberRole == 'Primary' || memberRole == 'Spouse' ? memberRole : 'Dependent' + signerDependentCount);
                signerList.add(signerMap);
            }
        } else {
            Integer signerIndex = 1;
            Map<String,Object> selectedRecipient = (Map<String,Object>)input.get('selectedRecipient');
            Map<String,Object> signerMap = new Map<String,Object>{
                'recipientId' => (String)selectedRecipient.get('recipientId'),
                'name' => (String)selectedRecipient.get('recipientName'),
                'email' => (String)selectedRecipient.get('recipientEmail'),
                'deliveryMethod' => 'Email',
                'roleName' => 'Primary'
            };
            signerList.add(signerMap);
            if (isPrimaryChange) {
                signerIndex++;
                signerDependentCount++;
                Map<String,Object> oldPrimarySignerMap = new Map<String,Object>{
                    'recipientId' => (String)oldPrimaryMap.get('recipientId'),
                    'name' => (String)oldPrimaryMap.get('recipientName'),
                    'email' => (String)oldPrimaryMap.get('recipientEmail'),
                    'deliveryMethod' => 'Email',
                    'roleName' => 'Dependent' + (signerDependentCount)
                };
                signerList.add(oldPrimarySignerMap);
            }
            if (isAddMember) {
                for (Map<String,Object> addMember : addMemberList) {
                    Integer memberAge = Integer.valueOf((String)addMember.get('Age'));
                    if (memberAge < 18) continue;
                    signerIndex++;
                    signerDependentCount++;
                    Map<String,Object> tmpSignerMap = new Map<String,Object>{
                        'recipientId' => (String)addMember.get('CensusMemberId'),
                        'name' => (String)addMember.get('FirstName') + ' ' + (String)addMember.get('LastName'),
                        'email' => (String)addMember.get('Email'),
                        'deliveryMethod' => 'Email',
                        'roleName' => (String)addMember.get('Relationship') == 'Spouse' ? 'Spouse' : 'Dependent' + (signerDependentCount)
                    };
                    signerList.add(tmpSignerMap);
                }
            }
        }

        return signerList;
    }

    private static List<String> getTemplatesIdList() {
        List<String> finalTemplatesIdList = new List<String>();

        // Get number of dependents
        Integer dependents = dependentCount;
        Boolean isChildFamily = isChildFamily;
        String primaryState = primaryState;
        String programType = medicalProgram.contains('Legacy') ? 'Senior' : medicalProgram.contains('Premier') ? 'Premier' : medicalProgram.contains('Access') ? 'Essential' : 'Enhanced';
        Boolean isLegacy = medicalProgram.contains('Legacy') ? true : false;

        // Section order map
        Map<String,Integer> orderMap = new Map<String,Integer>();
        if (isProgramChange) {
            orderMap = new Map<String,Integer> {
                'ProgramChange' => 1,
                'Application' => 2,
                'Program' => 3,
                'Beneficiaries' => 4,
                'Payment' => 5, 
                'State' => 6
            };
        } else {
            orderMap = new Map<String,Integer> {
                'Application' => 1,
                'Program' => 2,
                'Beneficiaries' => 3,
                'Payment' => 4,
                'State' => 5
            };   
        }

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
            sectionStr += ') \n';
            clausesList.add(sectionStr);
        }

        // Query
        String queryStr = 'SELECT Id, ARC_TemplateName__c, ARC_Section__c FROM ARC_DocuSignCompositeTemplates__c '; // Base query string
        if (clausesList != null && !clausesList.isEmpty()) {
            String allClausesStr = String.join(clausesList, ' OR ');
            queryStr += 'WHERE ' + allClausesStr;
        }

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


        for (Integer i = 1 ; i <= orderMap.keySet().size() ; i++) {
            if (orderToTemplateNameMap.containsKey(i)) {
                String tempNameToAdd = orderToTemplateNameMap.get(i);
                System.debug('Template ' + i + ': ' + tempNameToAdd);
                finalTemplatesIdList.add(tempNameToTempId.get(tempNameToAdd));
                templateNameList.add(tempNameToAdd);
            }
        }

        return finalTemplatesIdList;
    }

    private static Map<String,Object> getDocuSignTabs(Map<String,Object> input) {
        Map<String,Object> docuSignTabs = new Map<String,Object>();
        Map<String,String> textTabs = new Map<String,String>();
        Map<String,Boolean> checkboxtabs = new Map<String,Boolean>();
        List<String> addMemberList = new List<String>();
        List<String> removeMemberList = new List<String>();
        Map<String,Object> primaryMember = new Map<String,Object>();

        // Get required information from Input
        Map<String,Object> membersMap = (Map<String,Object>) input.get('membersMap');
        Map<String,Object> newMemberList = membersMap.containsKey('newMembers') && membersMap.get('newMembers') != null ? (Map<String,Object>)membersMap.get('newMembers') : new Map<string,Object>();
        Map<String,Object> oldMemberList = membersMap.containsKey('oldMembers') && membersMap.get('oldMembers') != null ? (Map<String,Object>)membersMap.get('oldMembers') : new Map<string,Object>();
        Map<String,Object> programsMap = (Map<String,Object>)input.get('programsMap');
        Map<String,Object> medicalQuestionsMap = (Map<String,Object>)input.get('medicalQuestionsMap');
        String effectiveDate = input.containsKey('effectiveDate') ? (String)input.get('effectiveDate') : '';
        String contractReason = input.containsKey('contractReasons') ? (String)input.get('contractReasons') : '';
        Boolean isChildFamily = input.containsKey('isChildFamily') && (Boolean)input.get('isChildFamily') ? true : false;
        Map<String,Object> beneficiariesMap = input.containsKey('beneficiariesMap') ? (Map<String,Object>)input.get('beneficiariesMap') : new Map<String,Object>();
        List<String> hipaaNameList = input.containsKey('hipaa') ? (List<String>)input.get('hipaa') : new List<String>();
        List<Map<String,Object>> signerList = input.containsKey('signerList') ? (List<Map<String,Object>>)input.get('signerList') : new List<Map<String,Object>>();
        

        if (!oldMemberList.isEmpty()) {
            for (String memberId : oldMemberList.keySet()) {
                Map<String,Object> memberMap = (Map<String,Object>)oldMemberList.get(memberId);
                String memberName = String.valueOf(memberMap.get('FirstName'))+ ' ' + String.valueOf(memberMap.get('LastName'));
                if (!newMemberList.containsKey(memberId)) removeMemberList.add(memberName); // Add member name to list if it is a member not included in new list
            }
        }

        Integer dependentIndex = 0; 
        Integer medicalNotesIndex = 0;
        Integer medicationsIndex = 0;
        Integer beneficiaryIndex = 0;
        if (!newMemberList.isEmpty()) {
            for (String memberId : newMemberList.keySet()) {
                Map<String,Object> memberMap = (Map<String,Object>)newMemberList.get(memberId);
                String memberName = String.valueOf(memberMap.get('FirstName'))+ ' ' + String.valueOf(memberMap.get('LastName'));
                String memberRelationship = (String)memberMap.get('Relationship');
                if (memberRelationship == 'Primary') primaryMember = memberMap;
                if (!oldMemberList.containsKey(memberId)) addMemberList.add(memberName); // Add member name to list if it is a member not included in old list
                dependentIndex = memberRelationship == 'Child' || memberRelationship == 'Temporary Newborn' ? dependentIndex + 1 : dependentIndex;
                for (String memberKey : memberMap.keySet()) {
                    if (memberMap.get(memberKey) != null) {
                        Object memberValue = memberMap.get(memberKey);
                        if (memberValue instanceOf String) {
                            if (memberKey.contains('Medicare')) {
                                textTabs.put(memberKey, (String)memberValue);
                            } else {
                            textTabs.put(memberRelationship == 'Primary' || memberRelationship == 'Spouse' ? memberRelationship + '.' + memberKey : 'Dependent' + (String.valueOf(dependentIndex)) + '.' + memberKey, (String)memberValue);
                            }
                        } else if (memberValue instanceOf Boolean) {
                            if (memberKey.contains('Medicare')) {
                                checkboxtabs.put(memberKey, (Boolean)memberValue);
                            } else {
                            checkboxtabs.put(memberRelationship == 'Primary' || memberRelationship == 'Spouse' ? memberRelationship + '.' + memberKey : 'Dependent' + (String.valueOf(dependentIndex)) + '.' + memberKey, (Boolean)memberValue);
                            }
                        }
                    }
                }
                // Get and Map member medical questions
                if (medicalQuestionsMap.containsKey(memberId)) {
                    Map<String,Object> memberMQMap = (Map<String,Object>)medicalQuestionsMap.get(memberId);
                    if (memberMQMap.containsKey('medicalConditions') && memberMQMap.get('medicalConditions') != null) {
                        Map<String,Object> medicalConditionsMap = (Map<String,Object>) memberMQMap.get('medicalConditions');
                        for (String key : medicalConditionsMap.keySet()) {
                            if (medicalConditionsMap.get(key) != null) {
                                Object value = medicalConditionsMap.get(key);
                                if (value instanceOf Boolean) {
                                    String tmpKey = memberRelationship == 'Primary' || memberRelationship == 'Spouse' ? 'SectionA ' + memberRelationship + ' ' + key : 'SectionA Dependent' + dependentIndex + ' ' + key;
                                    checkboxtabs.put(tmpKey, (Boolean)value);
                                } else if (key == 'CancersMap') {
                                    Map<String,Object> cancersMap = (Map<String,Object>)medicalConditionsMap.get('CancersMap');
                                    medicalNotesIndex++;
                                    textTabs.put('MemberRow' + medicalNotesIndex, memberName);
                                    textTabs.put('NoteRow' + medicalNotesIndex, 'Cancer: ' + (String)cancersMap.get('TypeOfCancer'));
                                    textTabs.put('DateRow' + medicalNotesIndex, (String)cancersMap.get('YearDiagnosed'));
                                } else if (key == 'PastConditionsList') {
                                    List<String> pastConditionsList = (List<String>)medicalConditionsMap.get('PastConditionsList');
                                    medicalNotesIndex++;
                                    textTabs.put('MemberRow' + medicalNotesIndex, memberName);
                                    textTabs.put('NoteRow' + medicalNotesIndex, String.join(pastConditionsList, ', '));
                                    textTabs.put('DateRow' + medicalNotesIndex, 'N/A');
                                    String conditionsTmpKey = memberRelationship == 'Primary' ? 'P.' : memberRelationship == 'Spouse' ? 'S.' : 'D' + dependentIndex + '.';
                                    for (String condition : pastConditionsList) {
                                        checkboxtabs.put(conditionsTmpKey + pastConditionsDocuSignMap.get(condition), true);
                                    }
                                } else if (key == 'PrimaryCare') {
                                    String tmpNameKey = 'Physician NameRow';
                                    textTabs.put(memberRelationship == 'Primary' ? tmpNameKey + '1' : memberRelationship == 'Spouse' ? tmpNameKey + '2' : tmpNameKey + String.valueOf(dependentIndex+2), ((Map<String,Object>)value).containsKey('NameRow') ? (String)((Map<String,Object>)value).get('NameRow') : '');
                                    textTabs.put(memberRelationship == 'Primary' ? 'CityRow1' : memberRelationship == 'Spouse' ? 'CityRow2' : 'CityRow' + String.valueOf(dependentIndex+2), ((Map<String,Object>)value).containsKey('PhoneRow') ? (String)((Map<String,Object>)value).get('CityRow') : '');
                                    textTabs.put(memberRelationship == 'Primary' ? 'PhoneRow1' : memberRelationship == 'Spouse' ? 'PhoneRow2' : 'PhoneRow' + String.valueOf(dependentIndex+2), ((Map<String,Object>)value).containsKey('PhoneRow') ? (String)((Map<String,Object>)value).get('PhoneRow') : '');
                                }
                            }
                        }
                    }
                    if (memberMQMap.containsKey('consumerDrug') && memberMQMap.get('consumerDrug') != null) {
                        List<Object> consumerDrugList = (List<Object>)memberMQMap.get('consumerDrug');
                        for (Object consumerDrug : consumerDrugList) {
                            medicationsIndex++;
                            textTabs.put('Family MemberRow' + medicationsIndex, memberName);
                            Map<String,Object> consumerDrugMap = (Map<String,Object>)consumerDrug;
                            for (String key : consumerDrugMap.keySet()) {
                                textTabs.put(key + medicationsIndex, consumerDrugMap.get(key) != null ? (String)consumerDrugMap.get(key) : '');
                            }
                        }
                    }
                }

                // Map Beneficiaries
                if (beneficiariesMap.containsKey(memberId)) {
                    Map<String,Object> memberBeneficiaryMap = (Map<String,Object>)beneficiariesMap.get(memberId);
                    for (String beneficiaryType : memberBeneficiaryMap.keySet()) {
                        beneficiaryIndex++;
                        Map<String,Object> tmpMap = (Map<String,Object>)memberBeneficiaryMap.get(beneficiaryType);
                        textTabs.put('TXT_MemberName' + beneficiaryIndex, memberName);
                        textTabs.put('TXT_BeneficiaryType' + beneficiaryIndex, beneficiaryType);
                        for (String key : tmpMap.keySet()) {
                            textTabs.put(key + beneficiaryIndex, key == 'TXT_BeneficiaryRelationship' && tmpMap.get(key) == 'Other' ? (String)tmpMap.get('TXT_BeneficiaryRelationshipOther') : (String)tmpMap.get(key));
                        }
                    }
                }
            }
        }

        // Map program and plan related info
        textTabs.put('Plan.EffectiveDate', effectiveDate);
        textTabs.put('Info.ReasonForChange', contractReason);
        Map<String,Object> newProgramsMap = (Map<String,Object>)programsMap.get('newPrograms');
        List<String> membersPerProgramList = new List<String>();
        List<String> newProgramsList = new List<String>();
        String newMedicalProgram = '';
        for (String program : newProgramsMap.keySet()) {
            Map<String,Object> programMap = (Map<String,Object>)newProgramsMap.get(program);
            String programName = (String)programMap.get('programName');
            String programType = (String)programMap.get('programType');
            String programMembers = programMap.get('programMembers') != null && !((List<String>)programMap.get('programMembers')).isEmpty() ? String.join((List<String>)programMap.get('programMembers'), ', ') : '';
            newMedicalProgram = programType == 'Medical' ? programName : newMedicalProgram;
            if (programType == 'Medical' && !membersPerProgramList.isEmpty()) {
                membersPerProgramList.add(0, String.valueOf(programName + ': ' + programMembers));
            } else {
                membersPerProgramList.add(String.valueOf(programName + ': ' + programMembers));
            }
            newProgramsList.add(programName);
        }
        textTabs.put('Info.MembersPerProgram', String.join(membersPerProgramList, '\n'));
        textTabs.put('Info.MembersPerProgramNew', String.join(membersPerProgramList, '\n'));
        textTabs.put('Info.MembersPerProgramOld', String.join(membersPerProgramList, '\n'));
        textTabs.put('Info.CurrentProgram', String.join(newProgramsList, ', '));
        
        Map<String,Object> oldProgramsMap = (Map<String,Object>)programsMap.get('oldPrograms');
        List<String> oldMembersPerProgramList = new List<String>();
        List<String> oldProgramsList = new List<String>();
        if (oldProgramsMap != null && !oldProgramsMap.isEmpty()) {
            for (String program : oldProgramsMap.keySet()) {
                Map<String,Object> programMap = (Map<String,Object>)oldProgramsMap.get(program);
                String programName = (String)programMap.get('programName');
                String programType = (String)programMap.get('programType');
                String programMembers = programMap.get('programMembers') != null && !((List<String>)programMap.get('programMembers')).isEmpty() ? String.join((List<String>)programMap.get('programMembers'), ', ') : '';
                if (programType == 'Medical' && !oldMembersPerProgramList.isEmpty()) {
                    oldMembersPerProgramList.add(0, String.valueOf(programName + ': ' + programMembers));
                } else {
                    oldMembersPerProgramList.add(String.valueOf(programName + ': ' + programMembers));
                }
                oldProgramsList.add(programName);
            }
            textTabs.put('Info.MembersPerProgramOld', String.join(oldMembersPerProgramList, '\n'));
            textTabs.put('Info.CurrentProgram', String.join(oldProgramsList, ', '));
        }


        List<String> contractReasonList = contractReason.split(';');
        List<String> requestedChangesList = new List<String>();
        for (String reason : contractReasonList) {
            String tmpReason = effectiveDate + ' ' + reason;
            if (reason == 'Program Upgrade' || reason == 'Program Downgrade') {
                tmpReason += ' to ' + newMedicalProgram;
            } else if (reason == 'Remove Member' || reason == 'Add Member' || reason == 'Add Existing Member') {
                if (reason == 'Remove Member') tmpReason += ' ' + String.join(removeMemberList, ', ');
                if (reason == 'Add Member' || reason == 'Add Existing Member') tmpReason += ' ' + String.join(addMemberList, ', ');
            } else if (reason == 'Add Ancillary Product') {
                tmpReason = effectiveDate + ' Ancillary Change';
            }
            requestedChangesList.add(tmpReason);
        }
        textTabs.put('Info.RequestedChanges', String.join(requestedChangesList, '\n'));

        // Map payment info
        Map<String,Object> paymentInfo = input.containsKey('paymentInfo') && input.get('paymentInfo') != null ? (Map<string,Object>)input.get('paymentInfo') : new Map<String,Object>();
        if (!paymentInfo.isEmpty()) {
            for (String key : paymentInfo.keySet()) {
                Object value = paymentInfo.get(key);
                if (value instanceOf String) {
                    textTabs.put('Payment.' + key, (String)value);
                } else if (value instanceOf Boolean) {
                    checkboxtabs.put('Payment.' + key, (Boolean)value);
                }
                if (key == 'MonthlyContribution') textTabs.put('Plan.MonthlyContribution', (String)paymentInfo.get(key));
                if (key == 'Fee') textTabs.put('Plan.ApplicationFee', (String)paymentInfo.get(key));
            }
        }

        // Map guardian info
        if (isChildFamily) {
            Map<String,Object> guardianMap = input.containsKey('guardianInfo') ? (Map<String,Object>)input.get('guardianInfo') : null;
            if (guardianMap != null) {
                for (String guardianKey : guardianMap.keySet()) {
                    if (guardianMap.get(guardianKey) != null) {
                        Object value = guardianMap.get(guardianKey);
                        if (value instanceOf String) {
                            textTabs.put('Guardian.' + guardianKey, (String)value);
                        } else if (value instanceOf Boolean) {
                            checkboxtabs.put('Guardian.' + guardianKey, (Boolean)value);
                        }
                    }
                }
            }
        }

        // Map California info
        String primaryState = primaryState;
        if (primaryState == 'CA') {
            Integer hipaaIndex = 0;
            Date primaryDOB = Date.valueOf((String)primaryMember.get('DOB'));
            textTabs.put('Primary.Name', (String)primaryMember.get('FirstName') + ' ' + (String)primaryMember.get('LastName'));
            textTabs.put('Primary.MonthOfBirth', String.valueOf(primaryDOB.month()));
            textTabs.put('Primary.DayOfBirth', String.valueOf(primaryDOB.day()));
            textTabs.put('Primary.YearOfBirth', String.valueOf(primaryDOB.year()));
            if (!hipaaNameList.isEmpty()) {
                for (String hippaName : hipaaNameList) {
                    hipaaIndex++;
                    textTabs.put('Hipaa' + hipaaIndex, hippaName);
                }
            }
            // Map DOB2
            for (Map<String,Object> signer : signerList) {
                String signerId = (String)signer.get('recipientId');
                String signerRole = (String)signer.get('roleName');
                String signerDOB = newMemberList.containsKey(signerId) ? (String)((Map<String,Object>)newMemberList.get(signerId)).get('DOB') : '';
                textTabs.put(signerRole + '.DOB2', signerDOB);
            }
        }

        // Build final tabs map
        docuSignTabs.put('tabs', new Map<String,Object>{
            'textTabs' => textTabs,
            'checkboxTabs' => checkboxtabs
        });
        return docuSignTabs;
    }

    public static void getNewEnvelopeId (Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        String contractId = (String) inputMap.get('contractId');
        Contract c = [SELECT Id,vlocity_ins__LastDocuSignEnvelopeId__c FROM Contract WHERE Id = :contractId LIMIT 1];
        outputMap.put('envelopeId', c.vlocity_ins__LastDocuSignEnvelopeId__c);
    }

    public static void voidOldEnvelope (Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        String oldEnvelopeId = (String)inputMap.get('oldEnvelopeId');
        List<String> oldEnvelopeList = new List<String>{oldEnvelopeId};
        ARC_DocuSignApiVoidEnvelope.voidEnvelopeAsync(oldEnvelopeList);
    }


    /******************AUXILIAR METHODS************************************* */

    private static Map<String,Object> formatMemberMap (Object memberInfo) {
        Map<String,Object> memberMapToReturn = new Map<String,Object>();
        if (memberInfo instanceOf ARC_ContractParticipant__c) {
            ARC_ContractParticipant__c cp = (ARC_ContractParticipant__c)memberInfo;
            String memberSSN = cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__SocialSecurityNumber__c;
            memberMapToReturn.put('CensusMemberId', cp.ARC_PersonAccount__r.Census_Member__c);
            memberMapToReturn.put('FirstName', cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c);
            memberMapToReturn.put('MI', cp.ARC_PersonAccount__r.Census_Member__r.ARC_MiddleInitial__c);
            memberMapToReturn.put('LastName', cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c);
            if(!Test.isRunningTest()) memberMapToReturn.put('SocialSecurity', 'XXX-XX-'+ memberSSN.right(4));
            memberMapToReturn.put('Address', cp.ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c);
            memberMapToReturn.put('City', cp.ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c);
            memberMapToReturn.put('State', cp.ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c);
            memberMapToReturn.put('ZipCode', cp.ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c);
            memberMapToReturn.put('Phone', cp.ARC_PersonAccount__r.Census_Member__r.ARC_Phone__c);
            memberMapToReturn.put('Email', cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Email__c);
            memberMapToReturn.put('DOB', String.valueOf(cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Birthdate__c));
            memberMapToReturn.put('Age', String.valueOf(cp.ARC_PersonAccount__r.Census_Member__r.ARC_Age__c));
            memberMapToReturn.put('Male', cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Gender__c == 'Male' ? true : false);
            memberMapToReturn.put('Female', cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Gender__c == 'Female' ? true : false);
            memberMapToReturn.put('Height', cp.ARC_PersonAccount__r.Census_Member__r.ARC_Height__c);
            memberMapToReturn.put('Weight', cp.ARC_PersonAccount__r.Census_Member__r.ARC_Weight__c);
            memberMapToReturn.put('Smoker', cp.ARC_PersonAccount__r.Census_Member__r.ARC_Smoker__c == true ? true : false);
            memberMapToReturn.put('NotSmoker', cp.ARC_PersonAccount__r.Census_Member__r.ARC_Smoker__c == true ? false : true);
            memberMapToReturn.put('Relationship', cp.ARC_Relationship__c);
            memberMapToReturn.put('Medicare.Number', cp.ARC_PersonAccount__r.Medicare_ID__c != null ? cp.ARC_PersonAccount__r.Medicare_ID__c : null );
            memberMapToReturn.put('Medicare.EffectiveDateA', cp.ARC_PersonAccount__r.Medicare_Part_A_Effective_Date__c != null ? String.valueOf(Date.valueOf(cp.ARC_PersonAccount__r.Medicare_Part_A_Effective_Date__c)) : null );
            memberMapToReturn.put('Medicare.EffectiveDateB', cp.ARC_PersonAccount__r.Medicare_Part_B_Effective_Date__c != null ? String.valueOf(Date.valueOf(cp.ARC_PersonAccount__r.Medicare_Part_B_Effective_Date__c)) : null );
            memberMapToReturn.put('Medicare.EffectiveDateD', cp.ARC_PersonAccount__r.Medicare_Part_D_Effective_Date__c != null ? String.valueOf(Date.valueOf(cp.ARC_PersonAccount__r.Medicare_Part_D_Effective_Date__c)) : null );
            memberMapToReturn.put('Medicare.PartA', cp.ARC_PersonAccount__r.Medicare_Part_A_Effective_Date__c != null ? true : false );
            memberMapToReturn.put('Medicare.PartB', cp.ARC_PersonAccount__r.Medicare_Part_B_Effective_Date__c != null ? true : false );
            memberMapToReturn.put('Medicare.PartD', cp.ARC_PersonAccount__r.Medicare_Part_D_Effective_Date__c != null ? true : false );

        }
        return memberMapToReturn;
    }

    private static Map<String,Object> getMemberMedicalQuestions (List<Id> censusMemberIdList) {
        Map<String,Object> memberToMedicalQuestionsMap = new Map<String,Object>();
        // Get Medical Questions records of members for Questions 1,2,3,4,5,6,7 and 9
        List<ARC_MedicalConditions__c> medicalConditionsList = [SELECT Id, 
                ARC_ParentsOrSiblingsDiagnosed__c, ARC_ParentsOrSiblingsDiagnosedNote__c, ARC_ParentsOrSiblingsDiagnosedDate__c, 
                ARC_UnexplainedConditions__c, ARC_Unexplained_Conditions_Notes__c, ARC_Unexplained_Conditions_Date__c,
                ARC_Tests__c, ARC_Tests_Notes__c, ARC_Tests_Date__c,
                ARC_IllegalDrugsAlcohol__c, ARC_Illegal_Drugs_Alcohol_Notes__c, ARC_Illegal_Drugs_Alcohol_Date__c,
                ARC_LicenceSuspended__c, ARC_LicenceSuspendedNote__c, ARC_LicenseSuspendedDate__c, 
                ARC_Condition__c, ARC_OtherConditions__c,
                ARC_Type_Of_Cancer__c, ARC_Year_Diagnosed_Cancer__c, ARC_Currently_Under_Treatment__c,
                ARC_CensusMember__c , ARC_CensusMember__r.Name, ARC_CensusMember__r.ARC_PhysicianCity__c, ARC_CensusMember__r.ARC_PhysicianName__c, ARC_CensusMember__r.ARC_PhysicianPhone__c
            FROM ARC_MedicalConditions__c 
            WHERE ARC_Active__c = true AND ARC_CensusMember__c IN :censusMemberIdList 
            ORDER BY CreatedDate ASC
        ];
        // Get Medical Questions record of members for Question 8
        List<vlocity_ins__ConsumerDrug__c> consumerDrugList = [SELECT Id, 
            Name, vlocity_ins__PrescribedBy__c, vlocity_ins__MedicationStartDate__c, vlocity_ins__MedicationEndDate__c, ARC_Reason__c, ARC_Active__c, ARC_CensusMember__c, ARC_CensusMember__r.Name 
            FROM vlocity_ins__ConsumerDrug__c 
            WHERE ARC_Active__c = true AND ARC_CensusMember__c IN :censusMemberIdList 
            ORDER BY CreatedDate ASC
        ];
        // Build medical questions map grouped by member
        for (ARC_MedicalConditions__c mc : medicalConditionsList) {
            String memberId = String.valueOf(mc.ARC_CensusMember__c);
            Map<String,Object> mcMap = getMedicalQuestionMap(mc);
            if (!memberToMedicalQuestionsMap.containsKey(memberId)) {
                memberToMedicalQuestionsMap.put(memberId, new Map<String,Object>{'medicalConditions' => mcMap});
            } else {
                Map<String,Object> tmpMqMap = (Map<String,Object>)((Map<String,Object>)memberToMedicalQuestionsMap.get(memberId)).get('medicalConditions');
                for (String key : tmpMqMap.keySet()) {
                    if (tmpMqMap.get(key) != null && tmpMqMap.get(key) == false) {
                        tmpMqMap.put(key, mcMap.get(key));
                        if ((key == 'Cancers' || key == 'PastConditions') && (Boolean)tmpMqMap.get(key) == true) {
                            if (key == 'Cancers') tmpMqMap.put('CancersMap', mcMap.get('CancersMap'));
                            if (key == 'PastConditions') tmpMqMap.put('PastConditionsList', mcMap.get('PastConditionsList'));
                        }
                    }    
                }
                ((Map<String,Object>)memberToMedicalQuestionsMap.get(memberId)).put('medicalConditions', tmpMqMap);
            }
        }
        for (vlocity_ins__ConsumerDrug__c cd : consumerDrugList) {
            String memberId = String.valueOf(cd.ARC_CensusMember__c);
            Map<String,Object> cdMap = getMedicalQuestionMap(cd);
            if (!memberToMedicalQuestionsMap.containsKey(memberId)) {
                memberToMedicalQuestionsMap.put(memberId, new Map<String,Object>{'consumerDrug' => new List<Object>{cdMap}});
            } else {
                if (((Map<String,Object>)memberToMedicalQuestionsMap.get(memberId)).containsKey('consumerDrug')) {
                    ((List<Object>)((Map<String,Object>)memberToMedicalQuestionsMap.get(memberId)).get('consumerDrug')).add(cdMap);
                } else {
                    ((Map<String,Object>)memberToMedicalQuestionsMap.get(memberId)).put('consumerDrug', new List<Object>{cdMap});
                }
            }
        }
        return memberToMedicalQuestionsMap;
    }

    private static Map<String,Object> getMedicalQuestionMap (Object medicalQuestion) {
        Map<String,Object> mqMapToReturn = new Map<String,Object>();
        if (medicalQuestion instanceOf ARC_MedicalConditions__c) {
            ARC_MedicalConditions__c mc = (ARC_MedicalConditions__c)medicalQuestion;
            // Build Boolean Map
            mqMapToReturn.put('UnexpectedSymptoms', mc.ARC_UnexplainedConditions__c);
            mqMapToReturn.put('PendingTests', mc.ARC_Tests__c);
            mqMapToReturn.put('Cancers', mc.ARC_Type_Of_Cancer__c != null ? true : false);
            mqMapToReturn.put('PastConditions', mc.ARC_Condition__c != null ? true : false);
            mqMapToReturn.put('Addictions', mc.ARC_IllegalDrugsAlcohol__c);
            mqMapToReturn.put('LicenceSuspended', mc.ARC_LicenceSuspended__c);
            // Add Cancer info to Map
            mqMapToReturn.put('CancersMap', mc.ARC_Type_Of_Cancer__c != null ? new Map<String,Object>{
                'TypeOfCancer' => String.valueOf(mc.ARC_Type_Of_Cancer__c), 
                'YearDiagnosed' => String.valueOf(mc.ARC_Year_Diagnosed_Cancer__c), 
                'UnderTreatment' => String.valueOf(mc.ARC_Currently_Under_Treatment__c)
            } : null);
            // Add Past Conditions List to Map
            String pastConditionsStr = mc.ARC_Condition__c;
            List<String> pastConditionsList = pastConditionsStr != null ? pastConditionsStr.split(';') : new List<String>();
            mqMapToReturn.put('PastConditionsList', !pastConditionsList.isEmpty() ? pastConditionsList : null);
            // Add Primary Care information to Map
            mqMapToReturn.put('PrimaryCare', mc.ARC_CensusMember__r.ARC_PhysicianName__c != null ? new Map<String,Object>{
                'NameRow' => String.valueOf(mc.ARC_CensusMember__r.ARC_PhysicianName__c),
                'CityRow' => String.valueOf(mc.ARC_CensusMember__r.ARC_PhysicianCity__c),
                'PhoneRow' => String.valueOf(mc.ARC_CensusMember__r.ARC_PhysicianPhone__c)
            } : null);
        } else if (medicalQuestion instanceOf vlocity_ins__ConsumerDrug__c) {
            vlocity_ins__ConsumerDrug__c cd = (vlocity_ins__ConsumerDrug__c)medicalQuestion;
            Date startDate = cd.vlocity_ins__MedicationStartDate__c != null ? cd.vlocity_ins__MedicationStartDate__c : null;
            Date endDate = cd.vlocity_ins__MedicationEndDate__c != null ? cd.vlocity_ins__MedicationEndDate__c : null;
            String datePrescribed = startDate != null ? String.valueOf(startDate.month()) + '/' + String.valueOf(startDate.year()) : null;
            String dateDiscontinued = endDate != null ? String.valueOf(endDate.month()) + '/' + String.valueOf(endDate.year()) : null;
            
            mqMapToReturn.put('Name of MedicationRow', cd.Name != null ? cd.Name : null);
            mqMapToReturn.put('Reason for MedicationRow', cd.ARC_Reason__c != null ? cd.ARC_Reason__c : null);
            mqMapToReturn.put('Date prescribed MoYrRow', datePrescribed != null ? datePrescribed : null);
            mqMapToReturn.put('Date Discontinued MoYrRow', dateDiscontinued != null ? dateDiscontinued : null);
            mqMapToReturn.put('Prescribing PhysicianRow', cd.vlocity_ins__PrescribedBy__c != null ? cd.vlocity_ins__PrescribedBy__c : null);
        }
        return mqMapToReturn;
    }

    private static Map<String,Object> getOldAndNewProgramsMap (Boolean isProgramChange, Id contractId, String eligibleContractId) {
        Map<String,Object> programsMapToReturn = new Map<String,Object>();
        List<vlocity_ins__GroupCensusMemberPlan__c> oldAndNewGCMP = [SELECT Id, Name, vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c, vlocity_ins__GroupCensusMemberId__r.Name, vlocity_ins__ContractLineId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :eligibleContractId];
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : oldAndNewGCMP) {
            String programName = gcmp.Name;
            String programType = gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c;
            String programMemberName = gcmp.vlocity_ins__GroupCensusMemberId__r.Name;
            String contractLineId = gcmp.vlocity_ins__ContractLineId__c;
            if (gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c == contractId) {
                if (!programsMapToReturn.containsKey('newPrograms')) {
                    programsMapToReturn.put('newPrograms', new Map<String,Map<String,Object>> {contractLineId => new Map<String,Object>{'programName' => programName, 'programType' => programType, 'programMembers' => new List<String>{programMemberName}}});
                } else {
                    Map<String,Map<String,Object>> newProgramsMap = (Map<String,Map<String,Object>>)programsMapToReturn.get('newPrograms');
                    if (newProgramsMap.containsKey(contractLineId)) {
                        ((List<String>)((Map<String,Object>)newProgramsMap.get(contractLineId)).get('programMembers')).add(programMemberName);
                    } else {
                        newProgramsMap.put(contractLineId, new Map<String,Object>{'programName' => programName, 'programType' => programType, 'programMembers' => new List<String>{programMemberName}});
                    }
                }
            }
            if (isProgramChange && gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c == eligibleContractId) {
                if (!programsMapToReturn.containsKey('oldPrograms')) {
                    programsMapToReturn.put('oldPrograms', new Map<String,Map<String,Object>> {contractLineId => new Map<String,Object>{'programName' => programName, 'programType' => programType, 'programMembers' => new List<String>{programMemberName}}});
                } else {
                    Map<String,Map<String,Object>> oldProgramsMap = (Map<String,Map<String,Object>>)programsMapToReturn.get('oldPrograms');
                    if (oldProgramsMap.containsKey(contractLineId)) {
                        ((List<String>)((Map<String,Object>)oldProgramsMap.get(contractLineId)).get('programMembers')).add(programMemberName);
                    } else {
                        oldProgramsMap.put(contractLineId, new Map<String,Object>{'programName' => programName, 'programType' => programType, 'programMembers' => new List<String>{programMemberName}});
                    }
                }
            }
        }
        if (!programsMapToReturn.containsKey('oldPrograms')) programsMapToReturn.put('oldPrograms', null);
        return programsMapToReturn;
    }

    private static Map<String,Object> getOldMemberList (String eligibleContractId) {
        Map<String,Object> memberListToReturn = new Map<String,Object>();
        List<ARC_ContractParticipant__c> oldMemberList = [SELECT Id,
            ARC_Relationship__c,
            ARC_PersonAccount__r.Census_Member__c,
            ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
            ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_MiddleInitial__c,
            ARC_PersonAccount__r.Census_Member__r.vlocity_ins__SocialSecurityNumber__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_Phone__c,
            ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Email__c,
            ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Birthdate__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_Age__c,
            ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Gender__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_Height__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_Weight__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_Smoker__c,
            ARC_PersonAccount__r.Census_Member__r.ARC_Relationship__c,
            ARC_PersonAccount__r.Medicare_ID__c,
            ARC_PersonAccount__r.Medicare_Part_A_Effective_Date__c,
            ARC_PersonAccount__r.Medicare_Part_B_Effective_Date__c,
            ARC_PersonAccount__r.Medicare_Part_D_Effective_Date__c
        FROM ARC_ContractParticipant__c 
        WHERE ARC_Contract__c = :eligibleContractId
        ];
        if (oldMemberList != null && !oldMemberList.isEmpty()) {
            for (ARC_ContractParticipant__c member : oldMemberList) {
                String cmId = (String)member.ARC_PersonAccount__r.Census_Member__c;
                String memberSSN = member.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__SocialSecurityNumber__c;
                Map<String,Object> cmMap = formatMemberMap(member);
                // memberListToReturn.add(cmMap);
                memberListToReturn.put(cmId, cmMap);
            }
        }
        return memberListToReturn;
    }

    private static Map<String,Object> getPaymentInfoMap (Contract c) {
        Boolean hasRecurring = c.ARC_RecurringMonthlyOrder__c != null ? true : false;
        Boolean hasAppChangeFee = c.ARC_AppFeeOrder__c != null ? true : false;
        String paymentType = hasRecurring ? String.valueOf(c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Method__c) : hasAppChangeFee ? String.valueOf(c.ARC_AppFeeOrder__r.ChargentOrders__Payment_Method__c) : '';
        Decimal paymentMonthlyContribution = hasRecurring ? c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Amount__c : c.ARC_TotalPrice__c;
        Decimal paymentFee = hasAppChangeFee ? c.ARC_AppFeeOrder__r.ChargentOrders__Total__c : 0;
        
        Map<String,Object> paymentMap = new Map<String,Object>{
            'CreditCardPayment' => paymentType == 'Credit Card' ? true : false,
            'BankAccountPayment' => paymentType == 'Bank Account' ? true : false, 
            'MonthlyContribution' => '$' + String.valueOf(paymentMonthlyContribution),
            'Fee' => '$' + String.valueOf(paymentFee),
            'FirstMonthFee' => '$' + String.valueOf(paymentMonthlyContribution + paymentFee)
        };

        String address = hasRecurring ? String.valueOf(c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c) : hasAppChangeFee ? String.valueOf(c.ARC_AppFeeOrder__r.ChargentOrders__Billing_Address__c) : '';
        String city = hasRecurring ? String.valueOf(c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c) : hasAppChangeFee ? String.valueOf(c.ARC_AppFeeOrder__r.ChargentOrders__Billing_City__c) : '';
        String state = hasRecurring ? String.valueOf(c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c) : hasAppChangeFee ? String.valueOf(c.ARC_AppFeeOrder__r.ChargentOrders__Billing_State__c) : '';
        String zipCode = hasRecurring ? String.valueOf(c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c) : hasAppChangeFee ? String.valueOf(c.ARC_AppFeeOrder__r.ChargentOrders__Billing_Zip_Postal__c) : '';
        List<String> addressList = new List<String>{address,city,state,zipCode};

        
        if (paymentType == 'Credit Card') {
            String cardNumber = hasRecurring ? 'XXXX-XXXX-XXXX-' + String.valueOf(c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Last_4__c) : hasAppChangeFee ? 'XXXX-XXXX-XXXX-' + String.valueOf(c.ARC_AppFeeOrder__r.ChargentOrders__Card_Last_4__c) : '';
            String cardExpYear = hasRecurring ? String.valueOf(c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Month_Indicator__c) + '/' + String.valueOf(c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Year_Indicator__c) : hasAppChangeFee ? String.valueOf(c.ARC_AppFeeOrder__r.ChargentOrders__Card_Month_Indicator__c) + '/' + String.valueOf(c.ARC_AppFeeOrder__r.ChargentOrders__Card_Year_Indicator__c) : '';
            paymentMap.put('NameOnCard', hasRecurring ? c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Credit_Card_Name__c : hasAppChangeFee ? c.ARC_AppFeeOrder__r.ChargentOrders__Credit_Card_Name__c : '');
            paymentMap.put('Visa', hasRecurring && c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Type__c == 'Visa' ? true : hasAppChangeFee && c.ARC_AppFeeOrder__r.ChargentOrders__Card_Type__c == 'Visa' ? true : false);
            paymentMap.put('Mastercard', hasRecurring && c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Type__c == 'Mastercard' ? true : hasAppChangeFee && c.ARC_AppFeeOrder__r.ChargentOrders__Card_Type__c == 'Mastercard' ? true : false);
            paymentMap.put('Discover', hasRecurring && c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Type__c == 'Discover' ? true : hasAppChangeFee && c.ARC_AppFeeOrder__r.ChargentOrders__Card_Type__c == 'Discover' ? true : false);
            paymentMap.put('CardNumber', cardNumber);
            paymentMap.put('CardExpYear', cardExpYear);
            paymentMap.put('BillingAddress', String.join(addressList, ', '));
        } else if (paymentType == 'Bank Account') {
            paymentMap.put('BankName', hasRecurring ? c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Name__c : hasAppChangeFee ? c.ARC_AppFeeOrder__r.ChargentOrders__Bank_Name__c : '');
            paymentMap.put('Checking', hasRecurring && c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Type__c == 'Checking' ? true : hasAppChangeFee && c.ARC_AppFeeOrder__r.ChargentOrders__Bank_Account_Type__c == 'Checking' ? true : false);
            paymentMap.put('Savings', hasRecurring && c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Type__c == 'Savings' ? true : hasAppChangeFee && c.ARC_AppFeeOrder__r.ChargentOrders__Bank_Account_Type__c == 'Savings' ? true : false);
            paymentMap.put('NameOnBankAccount', hasRecurring ? c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Name__c : hasAppChangeFee ? c.ARC_AppFeeOrder__r.ChargentOrders__Bank_Account_Name__c : '');
            paymentMap.put('AccountNumber', hasRecurring ? c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Number__c : hasAppChangeFee ? c.ARC_AppFeeOrder__r.ChargentOrders__Bank_Account_Number__c : '');
            paymentMap.put('Routing', hasRecurring ? c.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Routing_Number__c : hasAppChangeFee ? c.ARC_AppFeeOrder__r.ChargentOrders__Bank_Routing_Number__c : '');
        }

        return paymentMap;
    }

    private static Map<String,Object> getBeneficiariesMap (String contractId) {
        Map<String,Object> beneficiariesMap = new Map<String,Object>();
        List<ARC_CoverageParticipant__c> coverageParticipantList = [SELECT Id, ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.Census_Member__c,
            ARC_PrimaryBeneficiaryName__c, ARC_PrimaryBeneficiaryPhone__c, ARC_PrimaryBeneficiaryBirthdate__c, ARC_PrimaryBeneficiaryRelationship__c, ARC_PrimaryBeneficiaryOther__c,
            ARC_SecondaryBeneficiaryName__c, ARC_SecondaryBeneficiaryPhone__c, ARC_SecondaryBeneficiaryBirthdate__c, ARC_SecondaryBeneficiaryRelationship__c, ARC_SecondaryBeneficiaryOther__c
            FROM ARC_CoverageParticipant__c 
            WHERE ARC_Policy__r.ARC_Contract__c = :contractId AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
        ];

        if (!coverageParticipantList.isEmpty() && coverageParticipantList != null) {
            for (ARC_CoverageParticipant__c covPart : coverageParticipantList) {
                String memberId = String.valueOf(covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.Census_Member__c);
                Map<String,Object> memberBeneficiaryMap = new Map<String,Object>();
                if (covPart.ARC_PrimaryBeneficiaryName__c != null) {
                    Map<String,Object> primaryBeneficiaryMap = new Map<String,Object>{
                        'TXT_BeneficiaryName' => covPart.ARC_PrimaryBeneficiaryName__c != null ? covPart.ARC_PrimaryBeneficiaryName__c : null,
                        'TXT_BeneficiaryPhone' => covPart.ARC_PrimaryBeneficiaryPhone__c != null ? String.valueOf(covPart.ARC_PrimaryBeneficiaryPhone__c) : null,
                        'TXT_BeneficiaryDOB' => covPart.ARC_PrimaryBeneficiaryBirthdate__c != null ? String.valueOf(covPart.ARC_PrimaryBeneficiaryBirthdate__c) : null,
                        'TXT_BeneficiaryRelationship' => covPart.ARC_PrimaryBeneficiaryRelationship__c != null ? covPart.ARC_PrimaryBeneficiaryRelationship__c : null,
                        'TXT_BeneficiaryRelationshipOther' => covPart.ARC_PrimaryBeneficiaryOther__c != null ? covPart.ARC_PrimaryBeneficiaryOther__c : ''
                    };
                    memberBeneficiaryMap.put('Primary', primaryBeneficiaryMap);
                }
                if (covPart.ARC_SecondaryBeneficiaryName__c != null) {
                    Map<String,Object> secondaryBeneficiaryMap = new Map<String,Object>{
                        'TXT_BeneficiaryName' => covPart.ARC_SecondaryBeneficiaryName__c != null ? covPart.ARC_SecondaryBeneficiaryName__c : null,
                        'TXT_BeneficiaryPhone' => covPart.ARC_SecondaryBeneficiaryPhone__c != null ? String.valueOf(covPart.ARC_SecondaryBeneficiaryPhone__c) : null,
                        'TXT_BeneficiaryDOB' => covPart.ARC_SecondaryBeneficiaryBirthdate__c != null ? String.valueOf(covPart.ARC_SecondaryBeneficiaryBirthdate__c) : null,
                        'TXT_BeneficiaryRelationship' => covPart.ARC_SecondaryBeneficiaryRelationship__c != null ? covPart.ARC_SecondaryBeneficiaryRelationship__c : null,
                        'TXT_BeneficiaryRelationshipOther' => covPart.ARC_SecondaryBeneficiaryOther__c != null ? covPart.ARC_SecondaryBeneficiaryOther__c : ''
                    };
                    memberBeneficiaryMap.put('Secondary', secondaryBeneficiaryMap);
                }
                if (!beneficiariesMap.containsKey(memberId) && !memberBeneficiaryMap.isEmpty()) beneficiariesMap.put(memberId, memberBeneficiaryMap);
            }
        }

        return beneficiariesMap;
    }

}