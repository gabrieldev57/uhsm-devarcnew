public with sharing class ARC_PopulateClaimWithEDIHandler {
    public static Set<Id> createClaimFromInput(List<ARC_ClaimInput__c> inputClaims) {
        List<sObject> upsertListClaim = new List<sObject>();
        List<sObject> upsertListClaimItem = new List<sObject>();
        List<sObject> upsertListClaimCode = new List<sObject>();
        List<sObject> upsertListClaimCode2 = new List<sObject>();

        // GET ALL DATA NEEDED FOR THE MAPPING!
        Set<String> generalCodes = new Set<String>();
        Set<String> provNPIIds = new Set<String>();
        Set<String> memberIds = new Set<String>();
        Set<List<String>> member_query_values_combination = new Set<List<String>>();
        Set<String> caseNumbers = new Set<String>();
        List<Claim> mappingWorking = new List<Claim>();
        List<Claim> mappingWorking2 = new List<Claim>();
        List<Claim> mappingWorking3 = new List<Claim>();
        List<Claim> mappingFailed = new List<Claim>();
        Map<String, ARC_ClaimInput__c> claimInputMap = new Map<String, ARC_ClaimInput__c>();
        Id cProfessional = Schema.SObjectType.Claim.getRecordTypeInfosByDeveloperName().get('ARC_Professional').getRecordTypeId();
        Id cInstitutional = Schema.SObjectType.Claim.getRecordTypeInfosByDeveloperName().get('ARC_Institutional').getRecordTypeId();

        for (ARC_ClaimInput__c ipt : inputClaims) {
            if (ipt.ARC_InputJSON__c != null) {
                try {
                    List<Object> input = ARC_FlattenInputJSON.flattenJSON(ipt, ipt.ARC_Type__c);
                    Map<String, Object> clmJSON = (Map<String, Object>) input[0];
                    Map<String, Object> clmInformation = (Map<String, Object>) clmJSON.get('claimInformation');
                    Map<String, Object> patientInformation = (Map<String, Object>) clmJSON.get('patientInformation');
                    Map<String, Object> subscriberInformation = (Map<String, Object>) clmJSON.get('subscriberInformation');
                    List<Object> lineItems = (List<Object>) clmJSON.get('lineItems');

                    String first_name;
                    String last_name;
                    Date birthdate;
                    String billing_street;
                    String billing_city;
                    String billing_state;
                    String member_id;

                    Date dosFrom = null;
                    Date dosTo = null;

                    if ((Boolean) clmJSON.get('professional')) {
                        List<String> dates = String.valueOf((String) clmInformation.get('ServiceDateFromLineItem')).split('-');
                        if (dates.size() > 0) {
                            dosFrom = formatDate(dates[0]);
                            dosTo = formatDate(dates[0]);
                        }
                    } else if ((Boolean) clmJSON.get('institutional')) {
                        List<String> dates = String.valueOf((String) clmInformation.get('StatementDates.DateTimePeriod_03')).split('-');
                        List<String> dates2 = clmInformation.get('ServiceDateFromLineItem') != null
                            ? String.valueOf((String) clmInformation.get('ServiceDateFromLineItem')).split('-')
                            : new List<String>();
                        if (dates2.size() == 0)
                            dates2 = clmInformation.get('StatementDates.DateTimePeriod_03') != null
                                ? String.valueOf((String) clmInformation.get('StatementDates.DateTimePeriod_03')).split('-')
                                : new List<String>();
                        if (dates.size() == 2) {
                            dosFrom = formatDate(dates[0]);
                            dosTo = formatDate(dates[1]);
                        } else if (dates2.size() == 2) {
                            dosFrom = formatDate(dates[0]);
                            dosTo = formatDate(dates[1]);
                        }
                    }

                    Boolean isNewborn = false;
                    if (!patientInformation.isEmpty()) {
                        Date birthdatePatient = formatDate((String) patientInformation.get('DMG_PatientDemographicInformation.DependentBirthDate_02'));
                        isNewborn = dosFrom <= birthdatePatient.addDays(15);
                    }
 
                    // IF PATIENT INFORMATION EXISTS GET THE PATIENT INFORMATION IF ONLY THE SUBSCRIBER INFORMATION NODE COMES IN THE JSON GETS THE PATIENT INFORMATION FROM THE SUBSCRIBER NODE
                    if (!patientInformation.isEmpty()) {
                        first_name = (String) patientInformation.get('NM1_PatientName.ResponseContactFirstName_04');
                        last_name = (String) patientInformation.get('NM1_PatientName.ResponseContactLastorOrganizationName_03');
                        birthdate = formatDate((String) patientInformation.get('DMG_PatientDemographicInformation.DependentBirthDate_02'));
                        billing_street = (String) patientInformation.get('N3_PatientAddress.ResponseContactAddressLine_01');
                        billing_city = (String) patientInformation.get('N4_PatientCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01');
                        billing_state = (String) patientInformation.get('N4_PatientCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02');
                    }
                    if ((String) subscriberInformation.get('SubscriberName.ResponseContactIdentifier_09') != null) {
                        member_id = (String) subscriberInformation.get('SubscriberName.ResponseContactIdentifier_09');
                    }

                    member_query_values_combination.add(new List<String>{ first_name, last_name, String.valueOf(birthdate), billing_street, billing_city, billing_state, member_id });
                    
                    if (!subscriberInformation.isEmpty()) {
                        first_name = (String) subscriberInformation.get('SubscriberName.ResponseContactFirstName_04');
                        last_name = (String) subscriberInformation.get('SubscriberName.ResponseContactLastorOrganizationName_03');
                        birthdate = formatDate((String) subscriberInformation.get('SubscriberDemographicInformation.DependentBirthDate_02'));
                        billing_street = (String) subscriberInformation.get('SubscriberAddress.ResponseContactAddressLine_01');
                        billing_city = (String) subscriberInformation.get('SubscriberCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01');
                        billing_state = (String) subscriberInformation.get('SubscriberCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02');
                    }

                    member_query_values_combination.add(new List<String>{ first_name, last_name, String.valueOf(birthdate), billing_street, billing_city, billing_state, member_id });

                    for (Object itm : lineItems) {
                        Map<String, Object> item = (Map<String, Object>) itm;
                        generalCodes.add((String) item.get('CompositeMedicalProcedureIdentifier.ProcedureCode_02'));
                    }

                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_01.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_02.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_03.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_04.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_05.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_06.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_07.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_08.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_09.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_10.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_11.IndustryCode_02'));
                    generalCodes.add((String) clmInformation.get('HealthCareCodeInformation_12.IndustryCode_02'));

                    if ((String) clmInformation.get('HealthCareCodeInformation_01.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_01.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_02.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_02.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_03.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_03.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_04.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_04.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_05.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_05.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_06.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_06.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_07.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_07.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_08.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_08.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_09.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_09.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_10.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_10.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_11.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_11.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('HealthCareCodeInformation_12.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('HealthCareCodeInformation_12.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('DiagnosisRelatedGroup_DRG_Information.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('DiagnosisRelatedGroup_DRG_Information.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('AdmittingDiagnosis.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('AdmittingDiagnosis.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('PrincipalDiagnosis.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('PrincipalDiagnosis.IndustryCode_02')));
                    }
                    if ((String) clmInformation.get('PatientReason.IndustryCode_02') != null) {
                        generalCodes.add(parseCode((String) clmInformation.get('PatientReason.IndustryCode_02')));
                    }
                    generalCodes.add((String) clmInformation.get('PrincipalProcedureInformation_1.IndustryCode_02'));

                    if ((List<Object>) clmInformation.get('otherProcedureCodes') != null) {
                        for (Object c : (List<Object>) clmInformation.get('otherProcedureCodes')) {
                            Map<String, Object> codeMap = (Map<String, Object>) c;
                            if (String.valueOf((String) codeMap.get('OtherProcedureInformation.IndustryCode_02')).length() == 6) {
                                generalCodes.add('0' + (String) codeMap.get('OtherProcedureInformation.IndustryCode_02'));
                            } else {
                                generalCodes.add((String) codeMap.get('OtherProcedureInformation.IndustryCode_02'));
                            }
                        }
                    }
                    if ((List<Object>) clmInformation.get('externalCauseOfInjury') != null) {
                        for (Object c : (List<Object>) clmInformation.get('externalCauseOfInjury')) {
                            Map<String, Object> codeMap = (Map<String, Object>) c;

                            if ((String) codeMap.get('ExtCauseOfInjury.IndustryCode_02') != null) {
                                generalCodes.add(parseCode((String) codeMap.get('ExtCauseOfInjury.IndustryCode_02')));
                            }
                        }
                    }
                    if ((List<Object>) clmInformation.get('otherDiagnosisCodes') != null) {
                        for (Object c : (List<Object>) clmInformation.get('otherDiagnosisCodes')) {
                            Map<String, Object> codeMap = (Map<String, Object>) c;

                            if ((String) codeMap.get('DiagnosisCode.IndustryCode_02') != null) {
                                generalCodes.add(parseCode((String) codeMap.get('DiagnosisCode.IndustryCode_02')));
                            }
                        }
                    }
                    if ((String) clmInformation.get('PriorAuthorization.MemberGrouporPolicyNumber_02') != null)
                        caseNumbers.add((String) clmInformation.get('PriorAuthorization.MemberGrouporPolicyNumber_02'));

                    // CHECK IF THE PRACTITIONER IS ON RENDERING PROVIDER OR ATTENDING PROVIDER
                    if ((String) clmJSON.get('renderingProviderNPI') != null) {
                        provNPIIds.add((String) clmJSON.get('renderingProviderNPI'));
                    } else if ((String) clmJSON.get('attendingProviderNPI') != null) {
                        provNPIIds.add((String) clmJSON.get('attendingProviderNPI'));
                    }
                    if ((String) clmJSON.get('billingProviderNPI') != null)
                        provNPIIds.add((String) clmJSON.get('billingProviderNPI'));

                    claimInputMap.put(ipt.ARC_ExternalId__c, ipt);
                    // CREATE CLAIM
                    Claim workingClaim = new Claim();
                    workingClaim.Name = ipt.ARC_ExternalId__c;
                    workingClaim.SourceSystemIdentifier = ipt.ARC_ExternalId__c;
                    workingClaim.Status = 'Initial';
                    workingClaim.ARC_ClaimInput__c = ipt.Id;
                    workingClaim.RecordTypeId = ipt.ARC_Type__c == 'Professional' ? cProfessional : cInstitutional;

                    mappingWorking.add(workingClaim);
                } catch (Exception err) {
                    System.debug('1st catch');
                    String exceptionMessage = err.getMessage();
                    String exceptionStackTrace = err.getStackTraceString();
                    System.debug(exceptionMessage);
                    System.debug(exceptionStackTrace);
                    // CHANGE STATUS TO CLAIM INPUT AND CREATE THE CLAIM WITH MAPPING FAILED
                    ipt.ARC_Status__c = 'Failed';

                    Claim failedClaim = new Claim();
                    failedClaim.Name = ipt.ARC_ExternalId__c;
                    failedClaim.Status = 'Mapping Failed';
                    failedClaim.ARC_ClaimInput__c = ipt.Id;
                    mappingFailed.add(failedClaim);
                }
            }
        }

        // INSERT THE CLAIMS AND CHECK IF SOMEONE FAILED
        Set<String> failedInputs = new Set<String>();
        Database.UpsertResult[] results = Database.upsert(mappingWorking, false);
        for (Integer i = results.size() - 1; i >= 0; i--) {
            if (!results[i].isSuccess()) {
                failedInputs.add(mappingWorking[i].SourceSystemIdentifier);
                mappingWorking.remove(i);
            }
        }
        System.debug('failedInputs.size(): ' + failedInputs.size());
        if (failedInputs.size() > 0) {
            for (ARC_ClaimInput__c inp : inputClaims) {
                if (failedInputs.contains(inp.ARC_ExternalId__c)) {
                    inp.ARC_Status__c = 'Closed SMB';
                }
            }
        }

        // QUERY RECORDS AND CREATE MAPS TO RELATE DATA LATER
        Id rarcRT = Schema.SObjectType.vlocity_ins__Vlocitycode__c.getRecordTypeInfosByName().get('RARC').getRecordTypeId();

        List<vlocity_ins__VlocityCode__c> codes = [SELECT Name, Id FROM vlocity_ins__VlocityCode__c WHERE Name IN :generalCodes AND RecordTypeId != :rarcRT LIMIT 1000];
        List<Account> billing_providers = [SELECT Name, Id, ARC_NationalProviderId__c FROM Account WHERE ARC_NationalProviderId__c IN :provNPIIds LIMIT 1000];
        List<Account> attending_providers = [
            SELECT Id, ARC_NationalProviderIdentifier__pc
            FROM Account
            WHERE ARC_NationalProviderIdentifier__pc IN :provNPIIds AND RecordType.DeveloperName = 'Attending_Provider'
            LIMIT 1000
        ];
        List<RecordType> provRecordTypes = [
            SELECT Id, Name, sObjectType, DeveloperName
            FROM RecordType
            WHERE sObjectType = 'Account' AND (DeveloperName = 'Provider' OR DeveloperName = 'Attending_Provider')
            LIMIT 4
        ];
        List<RecordType> lineItemRecordTypes = [
            SELECT Id, Name, sObjectType, DeveloperName
            FROM RecordType
            WHERE sObjectType = 'ClaimCoveragePaymentDetail' AND (Name = 'Professional' OR Name = 'Institutional')
            LIMIT 4
        ];
        List<RecordType> claimCodesRT = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'ARC_Institutional_Claim_Code__c' LIMIT 20];

        String query_string = 'SELECT vlocity_ins__GroupCensusMemberId__r.Id, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c, vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressStreet__c,vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c,vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressCity__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__CensusId__c, vlocity_ins__GroupCensusMemberId__r.Member_ID__c, vlocity_ins__GroupCensusMemberId__r.e123_member_id_from_policy__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Current_Member_Id__c, vlocity_ins__GroupCensusMemberId__r.e123_member_id__c,vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__RelatedCensusMemberId__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c,vlocity_ins__GroupCensusMemberId__r.CreatedDate ';
        query_string += 'FROM vlocity_ins__GroupCensusMemberPlan__c ';
        query_string += 'WHERE (vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = \'Medical\') AND ';

        // // build conditions for DOS and contract Dates:
        // String datesCondition = 'vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c <= [DOS] AND vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c <= [DOS] OR ';
        // datesCondition += 

        List<String> member_conditions = new List<String>();

        if (!member_query_values_combination.isEmpty()) {
            for (List<String> values : member_query_values_combination) {
                List<String> conditions = new List<String>();

                List<String> condition1 = new List<String>();
                List<String> condition2 = new List<String>();

                List<String> conditions_firstname = new List<String>();
                List<String> conditions_fullname_birthdate = new List<String>();
                List<String> or_conditions_member_id = new List<String>();
                List<String> or_conditions_optional_fields = new List<String>();

                // Build conditions for fullname and birthdate
                if (values[0] != null && values[1] != null) {
                    List<String> and_fullname_conditions1 = new List<String>();
                    List<String> and_fullname_conditions2 = new List<String>();
                    List<String> and_fullname_conditions3 = new List<String>();
                    List<String> or_fullname_conditions = new List<String>();

                    //Unsanitized
                    and_fullname_conditions1.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c LIKE \'%' + values[0] + '%\'');
                    and_fullname_conditions1.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c LIKE \'%' + values[1] + '%\'');

                    //Sanitized, without ' and -
                    and_fullname_conditions2.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c LIKE \'%' + values[0].replace('\'', '').replace('-', '') + '%\'');
                    and_fullname_conditions2.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c LIKE \'%' + values[1].replace('\'', '').replace('-', '') + '%\'');

                    and_fullname_conditions3.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c LIKE \'%' + values[0].replace('\'', '').replace('-', '').substringBefore(' ') + '%\'');
                    and_fullname_conditions3.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c LIKE \'%' + values[1].replace('\'', '').replace('-', '') + '%\'');

                    conditions_firstname.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c LIKE \'%' + values[0] + '%\'');
                    conditions_firstname.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c LIKE \'%' + values[0].replace('\'', '').replace('-', '') + '%\'');
                    conditions_firstname.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c LIKE \'%' + values[0].replace('\'', '').replace('-', '').substringBefore(' ') + '%\'');

                    or_fullname_conditions.add('(' + String.join(and_fullname_conditions1, ' AND ') + ')');
                    or_fullname_conditions.add('(' + String.join(and_fullname_conditions2, ' AND ') + ')');
                    or_fullname_conditions.add('(' + String.join(and_fullname_conditions3, ' AND ') + ')');

                    conditions_fullname_birthdate.add('(' + String.join(or_fullname_conditions, ' OR ') + ')');
                }

                if (values[2] != null) {
                    conditions_fullname_birthdate.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c = ' + values[2]);
                }

                // Build conditions for member ID
                if (values[6] != null) {
                    or_conditions_member_id.add('vlocity_ins__GroupCensusMemberId__r.Member_ID__c LIKE \'' + values[6] + '\'');
                    or_conditions_member_id.add('vlocity_ins__GroupCensusMemberId__r.e123_member_id_from_policy__c LIKE \'' + values[6] + '\'');
                    or_conditions_member_id.add('vlocity_ins__GroupCensusMemberId__r.e123_member_id__c LIKE \'' + values[6] + '\'');
                    or_conditions_member_id.add('vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Current_Member_Id__c LIKE \'' + values[6] + '\'');
                }

                // Build conditions for optional fields
                if (values[3] != null || values[4] != null || values[5] != null || values[6] != null) {
                    if (!or_conditions_member_id.isEmpty()) {
                        or_conditions_optional_fields.addAll(or_conditions_member_id);
                    }

                    if (values[3] != null) {
                        or_conditions_optional_fields.add('vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressStreet__c LIKE \'%' + String.escapeSingleQuotes(values[3]) + '%\'');
                    }
                    if (values[4] != null) {
                        or_conditions_optional_fields.add('vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressCity__c LIKE \'%' + String.escapeSingleQuotes(values[4]) + '%\'');
                    }
                    if (values[5] != null) {
                        or_conditions_optional_fields.add('vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c = \'' + values[5] + '\'');
                    }
                }

                // 1. Firstname and Member Id
                if (values[0] != null && !conditions_firstname.isEmpty()) {
                    condition1.add('(' + String.join(conditions_firstname, ' OR ') + ')');
                    condition1.add('(' + String.join(or_conditions_member_id, ' OR ') + ')');
                    if (!condition1.isEmpty()) {
                        conditions.add('(' + String.join(condition1, ' AND ') + ')');
                    }
                }

                // 2. Fullname or Birthdate AND Optional fields
                if ((values[0] != null || values[1] != null) && !conditions_fullname_birthdate.isEmpty() && !or_conditions_optional_fields.isEmpty()) {
                    condition2.add('(' + String.join(conditions_fullname_birthdate, ' OR ') + ')');
                    condition2.add('(' + String.join(or_conditions_optional_fields, ' OR ') + ')');
                    if (!condition2.isEmpty()) {
                        conditions.add('(' + String.join(condition2, ' AND ') + ')');
                    }
                }

                // 3. Just Fullname AND Birthdate
                if (values[0] != null && values[1] != null && !conditions_fullname_birthdate.isEmpty()) {
                    conditions.add('(' + String.join(conditions_fullname_birthdate, ' AND ') + ')');
                }

                //// 4. Just Member Id
                //if (values[0] != null && !or_conditions_member_id.isEmpty()) {
                //    conditions.add('(' + String.join(or_conditions_member_id, ' OR ') + ')');
                //}

                // Combine conditions for this member
                if (!conditions.isEmpty()) {
                    member_conditions.add('(' + String.join(conditions, ' OR ') + ')');
                }
            }

            query_string += '(' + String.join(member_conditions, ' OR ') + ')';

            // Debug the where_clause in chunks of 40 characters

            // Integer chunk_size = 40;
            // for (Integer j = 0; j < query_string.length(); j += chunk_size) {
            //     String chunk = query_string.substring(j, Math.min(j + chunk_size, query_string.length()));
            //     System.debug(chunk);
            // }
			
            System.debug(LoggingLevel.ERROR, 'Full Query: ' + query_string);
            
            List<vlocity_ins__GroupCensusMemberPlan__c> members = Database.query(query_string);

            System.debug( '>>>> Members size >>>> ' + members.size());
            provRecordTypes.addAll(lineItemRecordTypes);
            Id rtBilling = null;
            Id rtRendering = null;
            Id rtLineProf = null;
            Id rtLineInst = null;
            Set<Id> member_contract_ids = new Set<Id>();
            Set<Id> memberCensus2 = new Set<Id>();
            Map<String, Id> codeName_codeId = new Map<String, Id>();
            Map<String, Account> billing_provider_NPI_to_account = new Map<String, Account>();
            Map<String, Account> attending_provider_NPI_to_account = new Map<String, Account>();
            Map<Id, String> clmId_rtName = new Map<Id, String>();
            Map<String, List<String>> memberkey_to_contractids = new Map<String, List<String>>();

            for (vlocity_ins__VlocityCode__c code : codes)
                codeName_codeId.put(code.Name, code.Id);

            for (Account a : billing_providers)
                billing_provider_NPI_to_account.put(a.ARC_NationalProviderId__c, a);

            for (Account a : attending_providers)
                attending_provider_NPI_to_account.put(a.ARC_NationalProviderIdentifier__pc, a);

            for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : members) {
                member_contract_ids.add(memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c);

                // 0: FirstName, 1: LastName, 2: Birthdate, 3: Street, 4: City, 5: State, 6: memberId1, 7: memberId2, 8: memberId3, 9: memberId4
                // 10: GroupCensusMemberId, 11: ContactId, 12: RelatedCensusMemberId, 13: RelatedCensusMember-ContactId
                // 14: GroupCensusMember-CreatedDate
                String memberKey = '';

                // 0: FirstName, 
                memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c != null
                    ? memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c + '|'
                    : 'NO_VALUE|';
                // 1: LastName, 
                memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c != null
                    ? memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c + '|'
                    : 'NO_VALUE|';
                //2: Birthdate
                memberKey += String.valueOf(memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c) != null
                    ? String.valueOf(memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c) + '|'
                    : 'NO_VALUE|';
                //3: Street, 
                memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressStreet__c != null
                    ? memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressStreet__c + '|'
                    : 'NO_VALUE|';
                // 4: City,
                memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressCity__c != null
                    ? memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressCity__c + '|'
                    : 'NO_VALUE|';
                // 5: State, 
                    memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c != null
                    ? memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c + '|'
                    : 'NO_VALUE|';

                String memberId1 = memberPlan.vlocity_ins__GroupCensusMemberId__r.Member_ID__c;
                String memberId2 = memberPlan.vlocity_ins__GroupCensusMemberId__r.e123_member_id_from_policy__c;
                String memberId3 = memberPlan.vlocity_ins__GroupCensusMemberId__r.e123_member_id__c;
                String memberId4 = memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r?.Account?.Current_Member_Id__c;

                List<String> member_id_list = new List<String>{ memberId1, memberId2, memberId3, memberId4 };
                //6: memberId1, 7: memberId2, 8: memberId3, 9: memberId
                for (Integer i = 0; i < member_id_list.size(); i++) {
                    String member_id = member_id_list[i];
                    if (member_id != null)
                        memberKey += member_id + '|';
                    else
                        memberKey += 'NO_VALUE|';
                }
                // 10: GroupCensusMemberId, 
                memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.Id != null ? String.valueOf(memberPlan.vlocity_ins__GroupCensusMemberId__r.Id) + '|' : 'NO_VALUE|';
                //11: ContactId, 
                memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c != null
                    ? String.valueOf(memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c) + '|'
                    : 'NO_VALUE|';
                //12: RelatedCensusMemberId,     
                memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__RelatedCensusMemberId__c != null
                    ? String.valueOf(memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__RelatedCensusMemberId__c) + '|'
                    : 'NO_VALUE|';
                //13: RelatedCensusMember-ContactId
                memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c != null
                    ? String.valueOf(memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c) + '|'
                    : 'NO_VALUE|';
                    
                // 14: GroupCensusMember-CreatedDate
                memberKey += memberPlan.vlocity_ins__GroupCensusMemberId__r.CreatedDate != null
                    ? String.valueOf(memberPlan.vlocity_ins__GroupCensusMemberId__r.CreatedDate)
                    : 'NO_VALUE';

                if (memberkey_to_contractids.containsKey(memberKey) == false) {
                    memberkey_to_contractids.put(memberKey, new List<String>());
                }

                ((List<String>) memberkey_to_contractids.get(memberKey)).add(memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c);
            }

            System.debug('>>KEYS<<: ' + memberkey_to_contractids.keySet());

            for (RecordType rtId : provRecordTypes) {
                if (rtId.sObjectType == 'Account' && rtId.DeveloperName == 'Provider')
                    rtBilling = rtId.Id;
                if (rtId.sObjectType == 'Account' && rtId.DeveloperName == 'Attending_Provider')
                    rtRendering = rtId.Id;
                if (rtId.sObjectType == 'ClaimCoveragePaymentDetail' && rtId.Name == 'Professional')
                    rtLineProf = rtId.Id;
                if (rtId.sObjectType == 'ClaimCoveragePaymentDetail' && rtId.Name == 'Institutional')
                    rtLineInst = rtId.Id;
            }

            System.debug('Contract Ids: ' + member_contract_ids);

            List<InsurancePolicy> policies = [
                SELECT
                    Id,
                    Name,
                    ARC_EffectiveDate__c,
                    ARC_ExpirationDate__c,
                    ARC_Contract__r.Status,
                    ARC_Contract__r.ARC_ContractReason__c,
                    ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c,
                    ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_VIP__c,
                    ARC_isActive__c,
                    (
                        SELECT
                            PrimaryParticipantContactId,
                            PrimaryParticipantContact.Birthdate,
                            PrimaryParticipantContact.FirstName,
                            PrimaryParticipantContact.LastName,
                            PrimaryParticipantContact.Name,
                            Role,
                            PrimaryParticipantContact.ARC_CensusMember__c
                        FROM InsurancePolicyParticipants
                    )
                FROM InsurancePolicy
                WHERE ARC_Contract__c IN :member_contract_ids
                ORDER BY ARC_EffectiveDate__c DESC
                LIMIT 1000
            ];

            Map<String, List<InsurancePolicy>> memberkey_to_policyList = new Map<String, List<InsurancePolicy>>();

            System.debug('Policies found: ' + policies.size());
            for (InsurancePolicy policy : policies) {
                for (String key : memberkey_to_contractids.keySet()) {
                    List<String> member_contractids_list = memberkey_to_contractids.get(key);

                    if (member_contractids_list.contains(policy.ARC_Contract__c)) {
                        if (memberkey_to_policyList.containsKey(key) == false) {
                            memberkey_to_policyList.put(key, new List<InsurancePolicy>());
                        }
                        ((List<InsurancePolicy>) memberkey_to_policyList.get(key)).add(policy);
                    }
                }
            }

            // CREATE DATA BEFORE UPDATE THE CLAIM
            List<ClaimCoverage> clmCoverages = new List<ClaimCoverage>();
            List<Account> billing_providers_for_upsert = new List<Account>();
            List<Account> attending_providers_for_upsert = new List<Account>();
            Map<Id, Id> claimId_CovId = new Map<Id, Id>();
            Map<Id, Account> claimid_to_billingprovideraccount = new Map<Id, Account>();
            Map<Id, Account> claimid_to_attendingprovideraccount = new Map<Id, Account>();
            System.debug('mappingWorking.size: ' + mappingWorking.size());
            for (Claim clm : mappingWorking) {
                // CHECK IF THE CLAIM WAS INSERTED
                ARC_ClaimInput__c ci = claimInputMap.get(clm.SourceSystemIdentifier);

                if (ci.ARC_InputJSON__c != null) {
                    try {
                        List<Object> input = ARC_FlattenInputJSON.flattenJSON(ci, ci.ARC_Type__c);
                        Map<String, Object> clmJSON = (Map<String, Object>) input[0];
                        Map<String, Object> billingProvider = (Map<String, Object>) clmJSON.get('billingProvider');
                        Map<String, Object> renderingProvider = (Map<String, Object>) clmJSON.get('renderingProvider');
                        Map<String, Object> attendingProvider = (Map<String, Object>) clmJSON.get('attendingProvider');

                        // CREATE CLAIM COVERAGE: NOT COVERED TO RELATE WITH THE LINE ITEMS
                        ClaimCoverage cc = new ClaimCoverage();
                        cc.ClaimId = clm.Id;
                        cc.InternalReserveMode = 'CoverageReserve';
                        cc.Name = 'Not covered';

                        // If the billing provider information is not empty in the input JSON, check whether there is an existing provider; if not, create a new account for the provider.
                        if (billingProvider?.isEmpty() == false) {
                            Account billing_provider_account;
                            String billing_provider_NPI = (String) clmJSON.get('billingProviderNPI');

                            // Check if the provider already exists in the map
                            if (billing_provider_NPI_to_account.get(billing_provider_NPI) != null) {
                                billing_provider_account = (Account) billing_provider_NPI_to_account.get(billing_provider_NPI);
                            } else {
                                billing_provider_account = new Account(); // Create a new account if it doesn't exist
                            }

                            // Retrieve billing provider names
                            String billingFirstname = (String) billingProvider.get('BillingProviderName.ResponseContactFirstName_04');
                            String billingLastname = (String) billingProvider.get('BillingProviderName.ResponseContactLastorOrganizationName_03');

                            // Update the provider's name if it's a new account
                            if (billing_provider_NPI_to_account.get(billing_provider_NPI) == null) {
                                billing_provider_account.Name = String.isNotBlank(billingFirstname) ? billingFirstname + ' ' + billingLastname : billingLastname;
                            }

                            // Populate billing provider account fields
                            billing_provider_account.RecordTypeId = rtBilling;
                            billing_provider_account.BillingCity = (String) billingProvider.get('BillingProviderCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01');
                            billing_provider_account.BillingCountry = 'United States';
                            billing_provider_account.BillingPostalCode = (String) billingProvider.get('BillingProviderCity_State_ZIPCode.AdditionalPatientInformationContactPostalZoneorZIPCode_03');
                            billing_provider_account.BillingState = (String) billingProvider.get('BillingProviderCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02');
                            billing_provider_account.BillingStreet = (String) billingProvider.get('BillingProviderAddress.ResponseContactAddressLine_01');
                            billing_provider_account.ARC_NationalProviderId__c = billing_provider_NPI;
                            billing_provider_account.ARC_BillingProviderJSON__c = (String) JSON.serializePretty(clmJSON.get('billingProvider'));

                            // Validate and set Tax ID if applicable
                            if ((String) billingProvider.get('BillingProviderTaxIdentification.MemberGrouporPolicyNumber_02') != null) {
                                if (String.valueOf((String) billingProvider.get('BillingProviderTaxIdentification.MemberGrouporPolicyNumber_02')).length() == 9) {
                                    billing_provider_account.vlocity_ins__TaxID__c = (String) billingProvider.get('BillingProviderTaxIdentification.MemberGrouporPolicyNumber_02');
                                }
                            }

                            // Update mappings and collections
                            claimid_to_billingprovideraccount.put(clm.Id, billing_provider_account);
                            billing_provider_NPI_to_account.put(billing_provider_account.ARC_NationalProviderId__c, billing_provider_account);

                            // Add to upsert collection if not already present
                            if (billing_providers_for_upsert.contains(billing_provider_account) == false) {
                                billing_providers_for_upsert.add(billing_provider_account);
                            }
                        }

                        // If the rendering provider information is not empty, check whether there is an existing provider; if not, create a new account for the provider.
                        if (renderingProvider?.isEmpty() == false) {
                            Account rendering_provider_account;
                            String rendering_provider_NPI = (String) clmJSON.get('renderingProviderNPI');

                            // Check if the provider already exists
                            if (attending_provider_NPI_to_account.get(rendering_provider_NPI) != null) {
                                rendering_provider_account = (Account) attending_provider_NPI_to_account.get(rendering_provider_NPI);
                            } else {
                                rendering_provider_account = new Account(); // Create a new account if it doesn't exist
                            }

                            rendering_provider_account.RecordTypeId = rtRendering;

                            // Set rendering provider names only if the provider does not already exist
                            if (attending_provider_NPI_to_account.get(rendering_provider_NPI) == null) {
                                rendering_provider_account.FirstName = (String) renderingProvider.get('RenderingProviderName.ResponseContactFirstName_04');
                                rendering_provider_account.LastName = (String) renderingProvider.get('RenderingProviderName.ResponseContactLastorOrganizationName_03');
                            }

                            // Populate rendering provider account fields
                            rendering_provider_account.ARC_NationalProviderIdentifier__pc = rendering_provider_NPI;
                            rendering_provider_account.ARC_RenderingProviderJSON__pc = (String) JSON.serializePretty(clmJSON.get('renderingProvider'));

                            // Update collections
                            if (attending_providers_for_upsert.contains(rendering_provider_account) == false) {
                                attending_providers_for_upsert.add(rendering_provider_account);
                            }

                            claimid_to_attendingprovideraccount.put(clm.Id, rendering_provider_account);
                            attending_provider_NPI_to_account.put(rendering_provider_account.ARC_NationalProviderIdentifier__pc, rendering_provider_account);
                        }
                        // If the attending provider information is not empty, check whether there is an existing provider; if not, create a new account for the provider.
                        else if (attendingProvider?.isEmpty() == false) {
                            Account attending_provider_account;
                            String attending_provider_NPI = (String) clmJSON.get('attendingProviderNPI');

                            // Check if the provider already exists
                            if (attending_provider_NPI_to_account.get(attending_provider_NPI) != null) {
                                attending_provider_account = (Account) attending_provider_NPI_to_account.get(attending_provider_NPI);
                            } else {
                                attending_provider_account = new Account(); // Create a new account if it doesn't exist
                            }

                            attending_provider_account.RecordTypeId = rtRendering;

                            // Set attending provider names only if the provider does not already exist
                            System.debug(attending_provider_NPI_to_account.get(attending_provider_NPI) != null);
                            if (attending_provider_NPI_to_account.get(attending_provider_NPI) == null) {
                                attending_provider_account.FirstName = (String) attendingProvider.get('AttendingProviderName.ResponseContactFirstName_04');
                                attending_provider_account.LastName = (String) attendingProvider.get('AttendingProviderName.ResponseContactLastorOrganizationName_03');
                            }

                            // Populate attending provider account fields
                            attending_provider_account.ARC_NationalProviderIdentifier__pc = attending_provider_NPI;
                            attending_provider_account.ARC_RenderingProviderJSON__pc = (String) JSON.serializePretty(clmJSON.get('attendingProvider'));

                            // Update collections
                            if (attending_providers_for_upsert.contains(attending_provider_account) == false) {
                                attending_providers_for_upsert.add(attending_provider_account);
                            }

                            claimid_to_attendingprovideraccount.put(clm.Id, attending_provider_account);
                            attending_provider_NPI_to_account.put(attending_provider_account.ARC_NationalProviderIdentifier__pc, attending_provider_account);
                        }

                        clmCoverages.add(cc);
                        mappingWorking2.add(clm);
                    } catch (Exception err) {
                        System.debug('2nd catch');
                        String exceptionMessage = err.getMessage();
                        String exceptionStackTrace = err.getStackTraceString();
                        System.debug(exceptionMessage);
                        System.debug(exceptionStackTrace);
                        clm.Status = 'Mapping Failed';
                        mappingFailed.add(clm);

                        ci.ARC_Status__c = 'Failed';
                    }
                }
            }

            insert clmCoverages;
            upsert attending_providers_for_upsert;
            upsert billing_providers_for_upsert;

            for (ClaimCoverage cc : clmCoverages)
                claimId_CovId.put(cc.ClaimId, cc.Id);
System.debug('mappingWorking2.size: ' + mappingWorking2.size());
            for (Claim clm : mappingWorking2) {
                ARC_ClaimInput__c ci = claimInputMap.get(clm.SourceSystemIdentifier);

                if (ci.ARC_InputJSON__c != null) {
                    try {
                        List<Object> input = ARC_FlattenInputJSON.flattenJSON(ci, ci.ARC_Type__c);

                        Map<String, Object> clmJSON = (Map<String, Object>) input[0];
                        Map<String, Object> clmInformation = (Map<String, Object>) clmJSON.get('claimInformation');
                        Map<String, Object> patientInformation = (Map<String, Object>) clmJSON.get('patientInformation');
                        Map<String, Object> subscriberInformation = (Map<String, Object>) clmJSON.get('subscriberInformation');
                        Map<String, Object> billingProvider = (Map<String, Object>) clmJSON.get('billingProvider');
                        Map<String, Object> renderingProvider = (Map<String, Object>) clmJSON.get('renderingProvider');
                        Map<String, Object> attendingProvider = (Map<String, Object>) clmJSON.get('attendingProvider');
                        List<Object> lineItems = (List<Object>) clmJSON.get('lineItems');

                        // Populate the providers information in the claim
                        clm.ARC_ServiceFacility__c = (String) JSON.serializePretty(clmJSON.get('serviceFacility'));
                        clm.ARC_SubmitterJSON__c = (String) JSON.serializePretty(clmJSON.get('submitter'));
                        clm.ARC_ReferringProvider__c = (String) JSON.serializePretty(clmJSON.get('referringProvider'));
                        clm.ARC_PatientJSON__c = (String) JSON.serializePretty(clmJSON.get('patientInformation'));
                        clm.ARC_Vendor__c = (Account) claimid_to_billingprovideraccount.get(clm.Id) != null ? ((Account) claimid_to_billingprovideraccount.get(clm.Id)).Id : null;
                        clm.ARC_Attending_Provider__c = (Account) claimid_to_attendingprovideraccount.get(clm.Id) != null
                            ? ((Account) claimid_to_attendingprovideraccount.get(clm.Id)).Id
                            : clm.ARC_Vendor__c;

                        if (renderingProvider?.isEmpty() == false) {
                            clm.ARC_AttendingProviderName__c = (String) renderingProvider.get('RenderingProviderName.ResponseContactFirstName_04') + ' ' + (String) renderingProvider.get('RenderingProviderName.ResponseContactLastorOrganizationName_03');
                        } else if (attendingProvider?.isEmpty() == false) {
                            clm.ARC_AttendingProviderName__c = (String)attendingProvider.get('AttendingProviderName.ResponseContactFirstName_04') + ' ' + (String) attendingProvider.get('AttendingProviderName.ResponseContactLastorOrganizationName_03');
                        }

                        // POPULATE CLAIM DATA
                        List<String> cCToCompare = new List<String>();
                        if ((String) clmInformation.get('Date_RepricerReceivedDate.DateTimePeriod_03') != null) {
                            clm.ARC_OriginalReceivedDate__c = formatDate((String) clmInformation.get('Date_RepricerReceivedDate.DateTimePeriod_03'));
                        }
                        if ((String) billingProvider.get('PayToAddress.ResponseContactAddressLine_01') != null) {
                            if ((String) billingProvider.get('PayToAddress.ResponseContactAddressLine_02') != null) {
                                clm.ARC_PayToStreet__c =
                                    (String) billingProvider.get('PayToAddress.ResponseContactAddressLine_01') +
                                    ', ' +
                                    (String) billingProvider.get('PayToAddress.ResponseContactAddressLine_02');
                            } else {
                                clm.ARC_PayToStreet__c = (String) billingProvider.get('PayToAddress.ResponseContactAddressLine_01');
                            }
                            clm.ARC_PayToCity__c = (String) billingProvider.get('PayToAddress.AdditionalPatientInformationContactCityName_01');
                            clm.ARC_PayTo_State__c = (String) billingProvider.get('PayToAddress.AdditionalPatientInformationContactStateCode_02');
                            clm.ARC_PayTo_ZipCode__c = (String) billingProvider.get('PayToAddress.AdditionalPatientInformationContactPostalZoneorZIPCode_03');
                        } else if (
                            (String) billingProvider.get('BillingProviderAddress.ResponseContactAddressLine_01') != null ||
                            (String) clmInformation.get('BillingProviderAddress.ResponseContactAddressLine_02') != null
                        ) {
                            if ((String) billingProvider.get('BillingProviderAddress.ResponseContactAddressLine_02') != null) {
                                clm.ARC_PayToStreet__c =
                                    (String) billingProvider.get('BillingProviderAddress.ResponseContactAddressLine_01') +
                                    ', ' +
                                    (String) billingProvider.get('BillingProviderAddress.ResponseContactAddressLine_02');
                            } else {
                                clm.ARC_PayToStreet__c = (String) billingProvider.get('BillingProviderAddress.ResponseContactAddressLine_01');
                            }
                            clm.ARC_PayToCity__c = (String) billingProvider.get('BillingProviderCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01');
                            clm.ARC_PayTo_State__c = (String) billingProvider.get('BillingProviderCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02');
                            clm.ARC_PayTo_ZipCode__c = (String) billingProvider.get('BillingProviderCity_State_ZIPCode.AdditionalPatientInformationContactPostalZoneorZIPCode_03');
                        }

                        clm.Status = 'Initial';
                        clm.ARC_MemberControlNumber__c = (String) clmInformation.get('ClaimInformation.PatientControlNumber_01');
                        clm.ARC_FilingIndicatorCode__c = (String) clmInformation.get('ClaimInformation.ClaimFilingIndicatorCode_03');
                        clm.ARC_ClaimStatusCode__c = (String) clmInformation.get('ClaimInformation.ClaimStatusCode_17');
                        clm.ARC_TransactionSetControlNumber__c = Integer.valueOf((String) clmJSON.get('TransactionSetControlNumber'));
                        clm.ARC_ClaimTotalAmount__c = Double.valueOf(clmInformation.get('ClaimInformation.TotalClaimChargeAmount_02'));
                        clm.ARC_PriorAuthorization__c = (String) clmInformation.get('PriorAuthorization.MemberGrouporPolicyNumber_02');
                        clm.ARC_RovType__c = 'Electronic Claim';
                        if ((String) clmInformation.get('ClaimInformation.BenefitsAssignmentCertificationIndicator_08') == 'Y')
                            clm.ARC_ReleaseInformation__c = 'Release agreement';
                        else if ((String) clmInformation.get('ClaimInformation.BenefitsAssignmentCertificationIndicator_08') == 'I')
                            clm.ARC_ReleaseInformation__c = 'Informed Consent';

                        // POPULATE DATA REGARDING IF IT'S A PROFESSIONAL OR INSTITUTIONAL CLAIM
                        if ((Boolean) clmJson.get('professional')) {
                            if ((String) clmInformation.get('HealthCareCodeInformation_01.IndustryCode_02') != null) {
                                String fullCodeA = (String) clmInformation.get('HealthCareCodeInformation_01.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeA)) != null)
                                    clm.DX_A__c = codeName_codeId.get(parseCode(fullCodeA));
                                else
                                    clm.DX_A__c = codeName_codeId.get(fullCodeA);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_01.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_02.IndustryCode_02') != null) {
                                String fullCodeB = (String) clmInformation.get('HealthCareCodeInformation_02.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeB)) != null)
                                    clm.DX_B__c = codeName_codeId.get(parseCode(fullCodeB));
                                else
                                    clm.DX_B__c = codeName_codeId.get(fullCodeB);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_02.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_03.IndustryCode_02') != null) {
                                String fullCodeC = (String) clmInformation.get('HealthCareCodeInformation_03.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeC)) != null)
                                    clm.DX_C__c = codeName_codeId.get(parseCode(fullCodeC));
                                else
                                    clm.DX_C__c = codeName_codeId.get(fullCodeC);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_03.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_04.IndustryCode_02') != null) {
                                String fullCodeD = (String) clmInformation.get('HealthCareCodeInformation_04.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeD)) != null)
                                    clm.DX_D__c = codeName_codeId.get(parseCode(fullCodeD));
                                else
                                    clm.DX_D__c = codeName_codeId.get(fullCodeD);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_04.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_05.IndustryCode_02') != null) {
                                String fullCodeE = (String) clmInformation.get('HealthCareCodeInformation_05.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeE)) != null)
                                    clm.DX_E__c = codeName_codeId.get(parseCode(fullCodeE));
                                else
                                    clm.DX_E__c = codeName_codeId.get(fullCodeE);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_05.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_06.IndustryCode_02') != null) {
                                String fullCodeF = (String) clmInformation.get('HealthCareCodeInformation_06.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeF)) != null)
                                    clm.DX_F__c = codeName_codeId.get(parseCode(fullCodeF));
                                else
                                    clm.DX_F__c = codeName_codeId.get(fullCodeF);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_06.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_07.IndustryCode_02') != null) {
                                String fullCodeG = (String) clmInformation.get('HealthCareCodeInformation_07.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeG)) != null)
                                    clm.DX_G__c = codeName_codeId.get(parseCode(fullCodeG));
                                else
                                    clm.DX_G__c = codeName_codeId.get(fullCodeG);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_07.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_08.IndustryCode_02') != null) {
                                String fullCodeH = (String) clmInformation.get('HealthCareCodeInformation_08.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeH)) != null)
                                    clm.DX_H__c = codeName_codeId.get(parseCode(fullCodeH));
                                else
                                    clm.DX_H__c = codeName_codeId.get(fullCodeH);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_08.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_09.IndustryCode_02') != null) {
                                String fullCodeI = (String) clmInformation.get('HealthCareCodeInformation_09.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeI)) != null)
                                    clm.DX_I__c = codeName_codeId.get(parseCode(fullCodeI));
                                else
                                    clm.DX_I__c = codeName_codeId.get(fullCodeI);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_09.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_10.IndustryCode_02') != null) {
                                String fullCodeJ = (String) clmInformation.get('HealthCareCodeInformation_10.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeJ)) != null)
                                    clm.DX_J__c = codeName_codeId.get(parseCode(fullCodeJ));
                                else
                                    clm.DX_J__c = codeName_codeId.get(fullCodeJ);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_10.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_11.IndustryCode_02') != null) {
                                String fullCodeK = (String) clmInformation.get('HealthCareCodeInformation_11.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeK)) != null)
                                    clm.DX_K__c = codeName_codeId.get(parseCode(fullCodeK));
                                else
                                    clm.DX_K__c = codeName_codeId.get(fullCodeK);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_11.IndustryCode_02'));
                            }
                            if ((String) clmInformation.get('HealthCareCodeInformation_12.IndustryCode_02') != null) {
                                String fullCodeL = (String) clmInformation.get('HealthCareCodeInformation_12.IndustryCode_02');
                                if (codeName_codeId.get(parseCode(fullCodeL)) != null)
                                    clm.DX_L__c = codeName_codeId.get(parseCode(fullCodeL));
                                else
                                    clm.DX_L__c = codeName_codeId.get(fullCodeL);
                                cCToCompare.add((String) clmInformation.get('HealthCareCodeInformation_12.IndustryCode_02'));
                            }

                            if ((String) clmInformation.get('ServiceDateFromLineItem') != null) {
                                List<String> dates = String.valueOf((String) clmInformation.get('ServiceDateFromLineItem')).split('-');
                                if (dates.size() > 0) {
                                    clm.ARC_DOSFrom__c = formatDate(dates[0]);
                                    clm.ARC_DOSTo__c = formatDate(dates[0]);
                                }
                            }

                            clm.ARC_NTE837IBNoteSegment__c = (String) clmInformation.get('ClaimNote.BillingNoteText_02');
                            clm.ARC_PlaceOfService__c = (String) clmInformation.get('HealthCareServiceLocationInformation.FacilityTypeCode_01');
                            if ((String) clmInformation.get('ClaimPricing_RepricingInformation.RepricingOrganizationIdentifier_04') != null) {
                                clm.ARC_ClaimNotes__c = (String) clmInformation.get('ClaimPricing_RepricingInformation.RepricingOrganizationIdentifier_04');
                            } else if ((String) clmInformation.get('ClaimPricing_RepricingInformation.ExceptionCode_15') != null) {
                                clm.ARC_ClaimNotes__c = (String) clmInformation.get('ClaimPricing_RepricingInformation.ExceptionCode_15');
                            }
                        } else if ((Boolean) clmJson.get('institutional')) {
                            List<String> dates = String.valueOf((String) clmInformation.get('StatementDates.DateTimePeriod_03')).split('-');
                            List<String> dates2 = clmInformation.get('ServiceDateFromLineItem') != null
                                ? String.valueOf((String) clmInformation.get('ServiceDateFromLineItem')).split('-')
                                : new List<String>();
                            if (dates2.size() == 0)
                                dates2 = clmInformation.get('StatementDates.DateTimePeriod_03') != null
                                    ? String.valueOf((String) clmInformation.get('StatementDates.DateTimePeriod_03')).split('-')
                                    : new List<String>();

                            if (dates.size() == 2) {
                                clm.ARC_DOSFrom__c = formatDate(dates[0]);
                                clm.ARC_SCPFrom__c = formatDate(dates[0]);

                                clm.ARC_DOSTo__c = formatDate(dates[1]);
                                clm.ARC_SCPThrough__c = formatDate(dates[1]);
                            } else if (dates2.size() == 2) {
                                clm.ARC_DOSFrom__c = formatDate(dates2[0]);
                                clm.ARC_DOSTo__c = formatDate(dates2[1]);
                            }

                            if ((String) clmInformation.get('AdmissionDate_Hour.DateTimePeriod_03') != null && (String) clmInformation.get('AdmissionDate_Hour.DateTimePeriod_03') != '000000000000') {
                                String admissionDate = String.valueOf((String) clmInformation.get('AdmissionDate_Hour.DateTimePeriod_03')).substring(0, 8);
                                String admissionHour = String.valueOf((String) clmInformation.get('AdmissionDate_Hour.DateTimePeriod_03')).substring(8, 12);

                                Integer year = Integer.valueOf(admissionDate.substring(0, 1) + admissionDate.substring(1, 2) + admissionDate.substring(2, 3) + admissionDate.substring(3, 4));
                                Integer month = Integer.valueOf(admissionDate.substring(4, 5) + admissionDate.substring(5, 6));
                                Integer day = Integer.valueOf(admissionDate.substring(6, 7) + admissionDate.substring(7, 8));
                                Integer hours = Integer.valueOf(admissionHour.substring(0, 2));
                                Integer minutes = Integer.valueOf(admissionHour.substring(2, 4));

                                Date addDate = date.newInstance(year, month, day);
                                Time addDateAndHours = Time.newInstance(hours, minutes, 0, 0);

                                clm.ARC_AdmissionHour__c = addDateAndHours;
                                clm.ARC_AdmissionDate__c = addDate;
                            }

                            if ((String) clmInformation.get('DischargeHour.DateTimePeriod_03') != null) {
                                String dischargeHour = (String) clmInformation.get('DischargeHour.DateTimePeriod_03');
                                Integer hour = Integer.valueOf(dischargeHour.substring(0, 2));
                                Integer minutes = Integer.valueOf(dischargeHour.substring(2, 4));

                                Time finalHour = Time.newInstance(hour, minutes, 0, 0);
                                clm.ARC_DischargeHour__c = finalHour;
                            }

                            clm.ARC_TypeofBill__c =
                                (String) clmInformation.get('HealthCareServiceLocationInformation.FacilityTypeCode_01') +
                                (String) clmInformation.get('HealthCareServiceLocationInformation.ClaimFrequencyTypeCode_03');
                            clm.ARC_AdmissionType__c = (String) clmInformation.get('InstitutionalClaimCode.AdmissionTypeCode_01');
                            clm.ARC_AdmissionSource__c = (String) clmInformation.get('InstitutionalClaimCode.AdmissionSourceCode_02');
                            clm.ARC_MemberStausCode__c = (String) clmInformation.get('InstitutionalClaimCode.PatientStatusCode_03');
                            clm.ARC_NTE837IBNoteSegment__c = (String) clmInformation.get('BillingNote.BillingNoteText_02');
                            clm.ARC_PlaceofService__c = createPlaceOfService(
                                (String) clmInformation.get('HealthCareServiceLocationInformation.FacilityTypeCode_01') +
                                (String) clmInformation.get('HealthCareServiceLocationInformation.ClaimFrequencyTypeCode_03')
                            );

                            // CODES INSTITUTIONAL
                            if ((String) clmInformation.get('PrincipalProcedureInformation_1.DateTimePeriod_04') != null) {
                                clm.ARC_Principal_Procedure_Date__c = formatDate((String) clmInformation.get('PrincipalProcedureInformation_1.DateTimePeriod_04'));
                            }
                            if ((String) clmInformation.get('AdmittingDiagnosis.IndustryCode_02') != null) {
                                if (codeName_codeId.get(parseCode((String) clmInformation.get('AdmittingDiagnosis.IndustryCode_02'))) != null) {
                                    clm.ARC_AdmitDX_Code__c = codeName_codeId.get(parseCode((String) clmInformation.get('AdmittingDiagnosis.IndustryCode_02')));
                                } else {
                                    clm.ARC_AdmitDX_Code__c = codeName_codeId.get(parseCode((String) clmInformation.get('AdmittingDiagnosis.IndustryCode_02')));
                                }

                                cCToCompare.add((String) clmInformation.get('AdmittingDiagnosis.IndustryCode_02'));
                            }

                            clm.ARC_Submitted_DRG_Code__c = codeName_codeId.get((String) clmInformation.get('DiagnosisRelatedGroup_DRG_Information.IndustryCode_02'));
                            clm.ARC_Principal_Procedure__c = codeName_codeId.get((String) clmInformation.get('PrincipalProcedureInformation_1.IndustryCode_02'));
                            if ((String) clmInformation.get('DiagnosisRelatedGroup_DRG_Information.IndustryCode_02') != null)
                                cCToCompare.add((String) clmInformation.get('DiagnosisRelatedGroup_DRG_Information.IndustryCode_02'));
                            if ((String) clmInformation.get('PrincipalProcedureInformation_1.IndustryCode_02') != null)
                                cCToCompare.add((String) clmInformation.get('PrincipalProcedureInformation_1.IndustryCode_02'));

                            Id rtOtherProcedure = null;
                            Id rtOccurenceCodes = null;
                            Id rtValueCodes = null;
                            Id rtOtherDiagnosis = null;
                            Id rtConditionCode = null;
                            Id rtECodes = null;
                            for (RecordType rt : claimCodesRT) {
                                if (rt.DeveloperName == 'ARC_Other_Procedure_Codes')
                                    rtOtherProcedure = rt.Id;
                                if (rt.DeveloperName == 'ARC_Occurrence_Codes_and_Dates')
                                    rtOccurenceCodes = rt.Id;
                                if (rt.DeveloperName == 'ARC_Value_Codes_and_Amount')
                                    rtValueCodes = rt.Id;
                                if (rt.DeveloperName == 'ARC_ICD_10_DX_and_POA')
                                    rtOtherDiagnosis = rt.Id;
                                if (rt.DeveloperName == 'ARC_Condition_Codes')
                                    rtConditionCode = rt.Id;
                                if (rt.DeveloperName == 'ARC_E_Codes')
                                    rtECodes = rt.Id;
                            }

                            if ((String) clmInformation.get('DiagnosisRelatedGroup_DRG_Information.IndustryCode_02') != null) {
                                String fullCode = (String) clmInformation.get('DiagnosisRelatedGroup_DRG_Information.IndustryCode_02');
                                Map<String, Object> inputMap = new Map<String, Object>();

                                inputMap.put('claimId', clm.Id);
                                inputMap.put('recordType', rtConditionCode);
                                if (codeName_codeId.get(parseCode(fullCode)) != null) {
                                    inputMap.put('conditionCode', codeName_codeId.get(parseCode(fullCode)));
                                } else {
                                    inputMap.put('conditionCode', codeName_codeId.get(fullCode));
                                }
                                ARC_Institutional_Claim_Code__c claimCode = createClaimCode(inputMap);
                                upsertListClaimCode.add(claimCode);
                                cCToCompare.add((String) clmInformation.get('PrincipalDiagnosis.IndustryCode_02'));
                            }

                            if ((String) clmInformation.get('PrincipalDiagnosis.IndustryCode_02') != null) {
                                String fullCode = (String) clmInformation.get('PrincipalDiagnosis.IndustryCode_02');
                                Map<String, Object> inputMap = new Map<String, Object>();

                                inputMap.put('claimId', clm.Id);
                                inputMap.put('recordType', rtOtherDiagnosis);
                                inputMap.put(
                                    'POA',
                                    (String) clmInformation.get('PrincipalDiagnosis.YesNoConditionorResponseCode_09') != null
                                        ? (String) clmInformation.get('PrincipalDiagnosis.YesNoConditionorResponseCode_09')
                                        : 'UNKNOWN'
                                );
                                if (codeName_codeId.get(parseCode(fullCode)) != null) {
                                    inputMap.put('otherDiagnosisCode', codeName_codeId.get(parseCode(fullCode)));
                                } else {
                                    inputMap.put('otherDiagnosisCode', codeName_codeId.get(fullCode));
                                }
                                ARC_Institutional_Claim_Code__c claimCode = createClaimCode(inputMap);
                                upsertListClaimCode2.add(claimCode);
                                cCToCompare.add((String) clmInformation.get('PrincipalDiagnosis.IndustryCode_02'));
                            }

                            if ((List<Object>) clmInformation.get('otherProcedureCodes') != null) {
                                for (Object c : (List<Object>) clmInformation.get('otherProcedureCodes')) {
                                    Map<String, Object> codeMap = (Map<String, Object>) c;
                                    Map<String, Object> inputMap = new Map<String, Object>();

                                    inputMap.put('claimId', clm.Id);
                                    inputMap.put('recordType', rtOtherProcedure);
                                    inputMap.put('date', (String) codeMap.get('OtherProcedureInformation.DateTimePeriod_04'));
                                    inputMap.put('otherProcedureId', codeName_codeId.get((String) codeMap.get('OtherProcedureInformation.IndustryCode_02')));

                                    ARC_Institutional_Claim_Code__c claimCode = createClaimCode(inputMap);
                                    upsertListClaimCode.add(claimCode);
                                    cCToCompare.add((String) codeMap.get('OtherProcedureInformation.IndustryCode_02'));
                                }
                            }

                            if ((List<Object>) clmInformation.get('occurrenceCodes') != null) {
                                for (Object c : (List<Object>) clmInformation.get('occurrenceCodes')) {
                                    Map<String, Object> codeMap = (Map<String, Object>) c;
                                    Map<String, Object> inputMap = new Map<String, Object>();

                                    inputMap.put('claimId', clm.Id);
                                    inputMap.put('recordType', rtOccurenceCodes);
                                    inputMap.put('date', (String) codeMap.get('OccurrenceInformationCode.DateTimePeriod_04'));
                                    inputMap.put('occurenceInformationCode', (String) codeMap.get('OccurrenceInformationCode.IndustryCode_02'));

                                    ARC_Institutional_Claim_Code__c claimCode = createClaimCode(inputMap);
                                    upsertListClaimCode.add(claimCode);
                                }
                            }

                            if ((List<Object>) clmInformation.get('valueCodes') != null) {
                                for (Object c : (List<Object>) clmInformation.get('valueCodes')) {
                                    Map<String, Object> codeMap = (Map<String, Object>) c;
                                    Map<String, Object> inputMap = new Map<String, Object>();

                                    inputMap.put('claimId', clm.Id);
                                    inputMap.put('recordType', rtValueCodes);
                                    inputMap.put('valueInformationCode', (String) codeMap.get('ValueCode.IndustryCode_02'));
                                    inputMap.put('valueAmount', (String) codeMap.get('ValueCode.MonetaryAmount_05'));

                                    ARC_Institutional_Claim_Code__c claimCode = createClaimCode(inputMap);
                                    upsertListClaimCode.add(claimCode);
                                }
                            }

                            if ((String) clmInformation.get('PatientReason.IndustryCode_02') != null) {
                                String fullCode = (String) clmInformation.get('PatientReason.IndustryCode_02');
                                Map<String, Object> inputMap = new Map<String, Object>();

                                inputMap.put('claimId', clm.Id);
                                inputMap.put('recordType', rtOtherDiagnosis);
                                inputMap.put(
                                    'POA',
                                    (String) clmInformation.get('PatientReason.YesNoConditionorResponseCode_09') != null
                                        ? (String) clmInformation.get('PatientReason.YesNoConditionorResponseCode_09')
                                        : 'UNKNOWN'
                                );
                                if (codeName_codeId.get(parseCode(fullCode)) != null) {
                                    inputMap.put('otherDiagnosisCode', codeName_codeId.get(parseCode(fullCode)));
                                } else {
                                    inputMap.put('otherDiagnosisCode', codeName_codeId.get(fullCode));
                                }
                                ARC_Institutional_Claim_Code__c claimCode = createClaimCode(inputMap);
                                upsertListClaimCode.add(claimCode);
                                cCToCompare.add((String) clmInformation.get('PatientReason.IndustryCode_02'));
                            }

                            if ((List<Object>) clmInformation.get('otherDiagnosisCodes') != null) {
                                for (Object c : (List<Object>) clmInformation.get('otherDiagnosisCodes')) {
                                    Map<String, Object> codeMap = (Map<String, Object>) c;
                                    Map<String, Object> inputMap = new Map<String, Object>();
                                    String fullCode = (String) codeMap.get('DiagnosisCode.IndustryCode_02');

                                    inputMap.put('claimId', clm.Id);
                                    inputMap.put('recordType', rtOtherDiagnosis);
                                    inputMap.put(
                                        'POA',
                                        (String) codeMap.get('DiagnosisCode.YesNoConditionorResponseCode_09') != null
                                            ? (String) codeMap.get('DiagnosisCode.YesNoConditionorResponseCode_09')
                                            : 'UNKNOWN'
                                    );
                                    if (codeName_codeId.get(parseCode(fullCode)) != null) {
                                        inputMap.put('otherDiagnosisCode', codeName_codeId.get(parseCode(fullCode)));
                                    } else {
                                        inputMap.put('otherDiagnosisCode', codeName_codeId.get(fullCode));
                                    }
                                    ARC_Institutional_Claim_Code__c claimCode = createClaimCode(inputMap);
                                    upsertListClaimCode.add(claimCode);
                                    cCToCompare.add((String) codeMap.get('DiagnosisCode.IndustryCode_02'));
                                }
                            }

                            if ((List<Object>) clmInformation.get('externalCauseOfInjury') != null) {
                                for (Object c : (List<Object>) clmInformation.get('externalCauseOfInjury')) {
                                    Map<String, Object> codeMap = (Map<String, Object>) c;
                                    Map<String, Object> inputMap = new Map<String, Object>();
                                    String fullCode = (String) codeMap.get('ExtCauseOfInjury.IndustryCode_02');

                                    inputMap.put('claimId', clm.Id);
                                    inputMap.put('recordType', rtECodes);
                                    if (codeName_codeId.get(parseCode(fullCode)) != null) {
                                        inputMap.put('eCode', codeName_codeId.get(parseCode(fullCode)));
                                    } else {
                                        inputMap.put('eCode', codeName_codeId.get(fullCode));
                                    }
                                    ARC_Institutional_Claim_Code__c claimCode = createClaimCode(inputMap);
                                    upsertListClaimCode.add(claimCode);
                                    cCToCompare.add((String) codeMap.get('ExtCauseOfInjury.IndustryCode_02'));
                                }
                            }
                        }

                        String first_name;
                        String last_name;
                        Date birthdate;
                        String billing_street;
                        String billing_city;
                        String billing_state;
                        String member_id;

                        Date dosFrom = null;
                        Date dosTo = null;

                        if ((Boolean) clmJson.get('professional')) {
                            List<String> dates = String.valueOf((String) clmInformation.get('ServiceDateFromLineItem')).split('-');
                            if (dates.size() > 0) {
                                dosFrom = formatDate(dates[0]);
                                dosTo = formatDate(dates[0]);
                            }
                        } else if ((Boolean) clmJson.get('institutional')) {
                            List<String> dates = String.valueOf((String) clmInformation.get('StatementDates.DateTimePeriod_03')).split('-');
                            List<String> dates2 = clmInformation.get('ServiceDateFromLineItem') != null
                                ? String.valueOf((String) clmInformation.get('ServiceDateFromLineItem')).split('-')
                                : new List<String>();
                            if (dates2.size() == 0)
                                dates2 = clmInformation.get('StatementDates.DateTimePeriod_03') != null
                                    ? String.valueOf((String) clmInformation.get('StatementDates.DateTimePeriod_03')).split('-')
                                    : new List<String>();

                            if (dates.size() == 2) {
                                dosFrom = formatDate(dates[0]);
                                dosTo = formatDate(dates[1]);
                            } else if (dates2.size() == 2) {
                                dosFrom = formatDate(dates[0]);
                                dosTo = formatDate(dates[1]);
                            }
                        }

                        Boolean isNewborn = false;
                        if (!patientInformation.isEmpty()) {
                            Date birthdatePatient = formatDate((String) patientInformation.get('DMG_PatientDemographicInformation.DependentBirthDate_02'));
                            isNewborn = dosFrom <= birthdatePatient.addDays(15);
                        }

                        // IF PATIENT INFORMATION EXISTS GET THE PATIENT INFORMATION IF ONLY THE SUBSCRIBER INFORMATION NODE COMES IN THE JSON GETS THE PATIENT INFORMATION FROM THE SUBSCRIBER NODE
                        if (!patientInformation.isEmpty()) {
                            first_name = (String) patientInformation.get('NM1_PatientName.ResponseContactFirstName_04');
                            last_name = (String) patientInformation.get('NM1_PatientName.ResponseContactLastorOrganizationName_03');
                            birthdate = formatDate((String) patientInformation.get('DMG_PatientDemographicInformation.DependentBirthDate_02'));
                            billing_street = (String) patientInformation.get('N3_PatientAddress.ResponseContactAddressLine_01');
                            billing_city = (String) patientInformation.get('N4_PatientCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01');
                            billing_state = (String) patientInformation.get('N4_PatientCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02');

                            clm.ARC_Name_Birthdate_Street__c = first_name + ' ' + last_name + ';' + birthdate + ';' + billing_street;
                        } else if (!subscriberInformation.isEmpty()) {
                            first_name = (String) subscriberInformation.get('SubscriberName.ResponseContactFirstName_04');
                            last_name = (String) subscriberInformation.get('SubscriberName.ResponseContactLastorOrganizationName_03');
                            birthdate = formatDate((String) subscriberInformation.get('SubscriberDemographicInformation.DependentBirthDate_02'));
                            billing_street = (String) subscriberInformation.get('SubscriberAddress.ResponseContactAddressLine_01');
                            billing_city = (String) subscriberInformation.get('SubscriberCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01');
                            billing_state = (String) subscriberInformation.get('SubscriberCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02');

                            clm.ARC_Name_Birthdate_Street__c = first_name + ' ' + last_name + ';' + birthdate + ';' + billing_street;
                        }

                        if ((String) subscriberInformation.get('SubscriberName.ResponseContactIdentifier_09') != null) {
                            member_id = (String) subscriberInformation.get('SubscriberName.ResponseContactIdentifier_09');
                        }

                        // POPULATE POLICY NUMBER AND PARTICIPANT
                        List<InsurancePolicy> patient_policies_list = new List<InsurancePolicy>();
                        String jsoninput_firstname_sanitized = first_name.replace('\'', '').replace('-', '');
                        String jsoninput_lastname_sanitized = last_name.replace('\'', '').replace('-', '');
                        String jsoninput_birthdate = String.valueOf(birthdate);
                        String jsoninput_street = billing_street;
                        String jsoninput_city = billing_city;
                        String jsoninput_state = billing_state;
                        String jsoninput_memberid = member_id;

                        Integer matches_name_birthdate = 0;
                        Integer matches_firstname_memberid = 0;
                        List<String> keys;
                        List<InsurancePolicy> values;

                        // POPULATE GROUP CENSUS MEMBER INFORMATION ON CLAIM

                        Integer highestScore = -1;
                        List<InsurancePolicy> bestPolicies;
                        String[] bestKeyValues;
                        String bestKey;

                        List<String> keys_name_and_dob;
                        List<InsurancePolicy> values_name_and_dob;
                        List<String> keys_name_and_member;
                        List<InsurancePolicy> values_name_and_member;
                        String selected_contact = '';
                        // Loop all member keys to find the most optimal match.
                        for (String key : memberkey_to_policyList.keySet()) {
                            // Split the key into its components, escaping the '|' character and then check each key separately
                            List<String> key_values = key.split('\\|');

                            String key_sanitized_firstname = key_values[0].replace('\'', '').replace('-', '');
                            String key_sanitized_lastname = key_values[1].replace('\'', '').replace('-', '');
                            DateTime createdDate = DateTime.valueOf(key_values[14]);

                            Boolean firstname_matches = key_sanitized_firstname != 'NO_VALUE' && jsoninput_firstname_sanitized != null
                                ? (key_sanitized_firstname.containsIgnoreCase(jsoninput_firstname_sanitized) ||
                                  key_sanitized_firstname.containsIgnoreCase(jsoninput_firstname_sanitized.substringBefore(' ')))
                                : false;
                            Boolean lastname_matches = key_sanitized_lastname != 'NO_VALUE' && jsoninput_lastname_sanitized != null ? key_sanitized_lastname.containsIgnoreCase(jsoninput_lastname_sanitized) : false;
                            Boolean birthdate_matches = key_values[2] != 'NO_VALUE' && jsoninput_birthdate != null ? key_values[2].containsIgnoreCase(jsoninput_birthdate) : false;
                            Boolean street_matches = key_values[3] != 'NO_VALUE' && jsoninput_street != null ? key_values[3].containsIgnoreCase(jsoninput_street) : false;
                            Boolean city_matches = key_values[4] != 'NO_VALUE' && jsoninput_city != null ? key_values[4].containsIgnoreCase(jsoninput_city) : false;
                            Boolean state_matches = key_values[5] != 'NO_VALUE' && jsoninput_state != null ? key_values[5].containsIgnoreCase(jsoninput_state) : false;

                            Boolean memberId_matches = jsoninput_memberid != null && (
                                key_values[6] != 'NO_VALUE' && key_values[6].containsIgnoreCase(jsoninput_memberid) ||
                                key_values[7] != 'NO_VALUE' && key_values[7].containsIgnoreCase(jsoninput_memberid) ||
                                key_values[8] != 'NO_VALUE' && key_values[8].containsIgnoreCase(jsoninput_memberid) ||
                                key_values[9] != 'NO_VALUE' && key_values[9].containsIgnoreCase(jsoninput_memberid))
                                ? true
                                : false;

                            // Calculates the score for the key and saves information if is best match
                            System.debug('firstName: ' + jsoninput_firstname_sanitized);
                            System.debug('lastName: ' + key_sanitized_lastname);
                            System.debug('DOB: ' + jsoninput_birthdate);
                            System.debug('street: ' + jsoninput_street);
                            System.debug('city: ' + jsoninput_city);
                            System.debug('state: ' + jsoninput_state);
                            Integer score = calculateMatchScore(firstname_matches, lastname_matches, birthdate_matches, memberId_matches, street_matches, city_matches, state_matches);
                            System.debug(memberkey_to_policyList.get(key));
                            System.debug('key-----> ' + key);
                            System.debug('Score---> ' + score);
                            String key_contactId = key_values[11];
                            if (selected_contact == key_contactId) {
                                bestPolicies.addAll((List<InsurancePolicy>) memberkey_to_policyList.get(key));
                            } else {
                                if (score > highestScore) {
                                    highestScore = score;
                                    bestKey = key;
                                    bestKeyValues = key_values;
                                    bestPolicies = (List<InsurancePolicy>) memberkey_to_policyList.get(key);
                                    selected_contact = key_contactId;
                                } else if (score != -1 && score == highestScore) {
                                    bestPolicies.addAll((List<InsurancePolicy>) memberkey_to_policyList.get(key));
                                } else if (score == -1) {
                                    if (firstname_matches && lastname_matches && birthdate_matches) {
                                        matches_name_birthdate += 1;
                                        if (matches_name_birthdate == 1) {
                                            selected_contact = key_contactId;
                                            keys_name_and_dob = key_values;
                                            values_name_and_dob = (List<InsurancePolicy>) memberkey_to_policyList.get(key);
                                        }
                                    } else if (memberId_matches && firstname_matches) {
                                        matches_firstname_memberid += 1;
                                        if (matches_firstname_memberid == 1) {
                                            selected_contact = key_contactId;
                                            keys_name_and_member = key_values;
                                            values_name_and_member = (List<InsurancePolicy>) memberkey_to_policyList.get(key);
                                        }
                                    }
                                }
                            }
                        }

                        if (bestKey != null) {
                            clm.ARC_PatientCensusMember__c = bestKeyValues[10] != 'NO_VALUE' ? bestKeyValues[10] : null;
                            clm.ARC_MemberContact__c = bestKeyValues[11] != 'NO_VALUE' ? bestKeyValues[11] : null;
                            clm.ARC_PrimaryMemberCM__c = bestKeyValues[12] != 'NO_VALUE' ? bestKeyValues[12] : null;
                            clm.ARC_Primary_Member__c = bestKeyValues[13] != 'NO_VALUE' ? bestKeyValues[13] : null;
                            patient_policies_list = bestPolicies;
                            System.debug(patient_policies_list);
                        }

                        if (patient_policies_list.isEmpty() == true && (matches_name_birthdate == 1 || matches_firstname_memberid == 1)) {
                            if (matches_name_birthdate == 1) {
                                keys = keys_name_and_dob;
                                values = values_name_and_dob;
                            } else if (matches_firstname_memberid == 1) {
                                keys = keys_name_and_member;
                                values = values_name_and_member;
                            }
                            patient_policies_list = values;
                            clm.ARC_PatientCensusMember__c = keys[10] != 'NO_VALUE' ? keys[10] : null;
                            clm.ARC_MemberContact__c = keys[11] != 'NO_VALUE' ? keys[11] : null;
                            clm.ARC_PrimaryMemberCM__c = keys[12] != 'NO_VALUE' ? keys[12] : null;
                            clm.ARC_Primary_Member__c = keys[13] != 'NO_VALUE' ? keys[13] : null;
                        }


                        // PATIENT NOT FOUND, SEARCH SUBSCRIBER

                        if (patient_policies_list.isEmpty() && !subscriberInformation.isEmpty() && !subscriberInformation.isEmpty()) {
                            // reset scores
                            highestScore = -1;
                            bestPolicies = null;
                            bestKeyValues = null;
                            bestKey = null;
                            selected_contact = '';

                            String primary_first_name = (String) subscriberInformation.get('SubscriberName.ResponseContactFirstName_04');
                            String primary_last_name = (String) subscriberInformation.get('SubscriberName.ResponseContactLastorOrganizationName_03');
                            Date primary_birthdate = formatDate((String) subscriberInformation.get('SubscriberDemographicInformation.DependentBirthDate_02'));
                            String primary_billing_street = (String) subscriberInformation.get('SubscriberAddress.ResponseContactAddressLine_01');
                            String primary_billing_city = (String) subscriberInformation.get('SubscriberCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01');
                            String primary_billing_state = (String) subscriberInformation.get('SubscriberCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02');
                            String primary_member_id;
                            if ((String) subscriberInformation.get('SubscriberName.ResponseContactIdentifier_09') != null) {
                                primary_member_id = (String) subscriberInformation.get('SubscriberName.ResponseContactIdentifier_09');
                            }
    
                            String jsoninput_primary_firstname_sanitized = primary_first_name.replace('\'', '').replace('-', '');
                            String jsoninput_primary_lastname_sanitized = primary_last_name.replace('\'', '').replace('-', '');
                            String jsoninput_primary_birthdate = String.valueOf(primary_birthdate);
                            String jsoninput_primary_street = primary_billing_street;
                            String jsoninput_primary_city = primary_billing_city;
                            String jsoninput_primary_state = primary_billing_state;
                            String jsoninput_primary_memberid = primary_member_id;
    
                            Integer matches_name_birthdate_primary = 0;
                            Integer matches_firstname_memberid_primary = 0;
                            //List<String> keys_primary;
    

                            List<String> keys_primary_name_and_dob;
                            List<String> keys_primary_name_and_member;
                            for (String key : memberkey_to_policyList.keySet()) {
                                // Split the key into its components, escaping the '|' character and then check each key separately
                                List<String> key_values = key.split('\\|');
    
                                String key_sanitized_firstname = key_values[0].replace('\'', '').replace('-', '');
                                String key_sanitized_lastname = key_values[1].replace('\'', '').replace('-', '');
                                DateTime createdDate = DateTime.valueOf(key_values[14]);
    
                                Boolean firstname_matches = key_sanitized_firstname != 'NO_VALUE' && jsoninput_primary_firstname_sanitized != null
                                    ? (key_sanitized_firstname.containsIgnoreCase(jsoninput_primary_firstname_sanitized) ||
                                      key_sanitized_firstname.containsIgnoreCase(jsoninput_primary_firstname_sanitized.substringBefore(' ')))
                                    : false;
                                Boolean lastname_matches = key_sanitized_lastname != 'NO_VALUE' && jsoninput_primary_lastname_sanitized != null ? key_sanitized_lastname.containsIgnoreCase(jsoninput_primary_lastname_sanitized) : false;
                                Boolean birthdate_matches = key_values[2] != 'NO_VALUE' && jsoninput_primary_birthdate != null ? key_values[2].containsIgnoreCase(jsoninput_primary_birthdate) : false;
                                Boolean street_matches = key_values[3] != 'NO_VALUE' && jsoninput_primary_street != null ? key_values[3].containsIgnoreCase(jsoninput_primary_street) : false;
                                Boolean city_matches = key_values[4] != 'NO_VALUE' && jsoninput_primary_city != null ? key_values[4].containsIgnoreCase(jsoninput_primary_city) : false;
                                Boolean state_matches = key_values[5] != 'NO_VALUE' && jsoninput_primary_state != null ? key_values[5].containsIgnoreCase(jsoninput_primary_state) : false;
    
                                Boolean memberId_matches = jsoninput_primary_memberid != null && (
                                    key_values[6] != 'NO_VALUE' && key_values[6].containsIgnoreCase(jsoninput_primary_memberid) ||
                                    key_values[7] != 'NO_VALUE' && key_values[7].containsIgnoreCase(jsoninput_primary_memberid) ||
                                    key_values[8] != 'NO_VALUE' && key_values[8].containsIgnoreCase(jsoninput_primary_memberid) ||
                                    key_values[9] != 'NO_VALUE' && key_values[9].containsIgnoreCase(jsoninput_primary_memberid))
                                    ? true
                                    : false;


                                // Calculates the score for the key and saves information if is best match
                                System.debug('firstName: ' + jsoninput_firstname_sanitized);
                                System.debug('lastName: ' + key_sanitized_lastname);
                                System.debug('DOB: ' + jsoninput_birthdate);
                                System.debug('street: ' + jsoninput_street);
                                System.debug('city: ' + jsoninput_city);
                                System.debug('state: ' + jsoninput_state);
                                Integer score = calculateMatchScore(firstname_matches, lastname_matches, birthdate_matches, memberId_matches, street_matches, city_matches, state_matches);
                                System.debug(memberkey_to_policyList.get(key));
                                System.debug('key-----> ' + key);
                                System.debug('Score---> ' + score);
                                String key_contactId = key_values[11];
                                if (selected_contact == key_contactId) {
                                    bestPolicies.addAll((List<InsurancePolicy>) memberkey_to_policyList.get(key));
                                } else {
                                    if (score > highestScore) {
                                        highestScore = score;
                                        bestKey = key;
                                        bestKeyValues = key_values;
                                        bestPolicies = (List<InsurancePolicy>) memberkey_to_policyList.get(key);
                                        selected_contact = key_contactId;
                                    } else if (score != -1 && score == highestScore) {
                                        bestPolicies.addAll((List<InsurancePolicy>) memberkey_to_policyList.get(key));
                                    } else if (score == -1) {
                                        if (firstname_matches && lastname_matches && birthdate_matches) {
                                            matches_name_birthdate += 1;
                                            if (matches_name_birthdate == 1) {
                                                keys_primary_name_and_dob = key_values;
                                                selected_contact = key_contactId;
                                            }
                                        } else if (memberId_matches && firstname_matches) {
                                            matches_firstname_memberid += 1;
                                            if (matches_firstname_memberid == 1) {
                                                keys_primary_name_and_member = key_values;
                                                selected_contact = key_contactId;
                                            }
                                        }
                                    }
                                }
                            }

                            if (bestKey != null) {
                                clm.ARC_PrimaryMemberCM__c = bestKeyValues[10] != 'NO_VALUE' ? bestKeyValues[10] : null;
                                clm.ARC_Primary_Member__c = bestKeyValues[11] != 'NO_VALUE' ? bestKeyValues[11] : null;
                                patient_policies_list = bestPolicies;
                                System.debug(patient_policies_list);
                            }

                            if (patient_policies_list.isEmpty() == true && (matches_name_birthdate == 1 || matches_firstname_memberid == 1)) {
                                if (matches_name_birthdate == 1) {
                                    clm.ARC_PrimaryMemberCM__c = keys_primary_name_and_dob[10] != 'NO_VALUE' ? keys_primary_name_and_dob[10] : null;
                                    clm.ARC_Primary_Member__c = keys_primary_name_and_dob[11] != 'NO_VALUE' ? keys_primary_name_and_dob[11] : null;
                                } else if (matches_firstname_memberid == 1) {
                                    clm.ARC_PrimaryMemberCM__c = keys_primary_name_and_member[10] != 'NO_VALUE' ? keys_primary_name_and_member[10] : null;
                                    clm.ARC_Primary_Member__c = keys_primary_name_and_member[11] != 'NO_VALUE' ? keys_primary_name_and_member[11] : null;
                                }
                            }
                            
                        }

                        Boolean found_valid_policy = false;
                        Boolean found_active_contract = false;

                        // POPULATE POLICY NUMBER, PARTICIPANTS AND CENSUS MEMBER
                        System.debug('-----POPULATE POLICY NUMBER, PARTICIPANTS AND CENSUS MEMBER-----');
                        for (InsurancePolicy policy : patient_policies_list) {
                            System.debug('POLICY ID: ' + policy.Id);
                            Boolean date_of_service_is_valid =
                                dosFrom >= policy.ARC_EffectiveDate__c && ((policy.ARC_ExpirationDate__c == null && policy.ARC_isActive__c) || policy.ARC_ExpirationDate__c >= dosTo);
                            
                            System.debug('dosFrom------------------> ' + dosFrom);
                            System.debug('dosFrom------------------> ' + dosTo);
                            System.debug('policy Effective Date----> ' + policy.ARC_EffectiveDate__c);
                            System.debug('policy Expiration date---> ' + policy.ARC_ExpirationDate__c);
                            System.debug('is Valid: ' + date_of_service_is_valid);
                            if (policy.ARC_Contract__c != null && policy.ARC_Contract__r.Status != 'Terminated' && policy.ARC_Contract__r.Status != 'Voided')
                                found_active_contract = true;
                            if (date_of_service_is_valid) {
                                found_valid_policy = true; // Mark valid policy found
                                clm.PolicyNumberId = policy.Id;
                                clm.ARC_VIP__c = policy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_VIP__c;
                                System.debug('*claim populated with policy*');
                                for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                                    String participant_firstname_sanitized = participant.PrimaryParticipantContact.FirstName.replace('\'', '').replace('-', '');
                                    String participant_lastname_sanitized = participant.PrimaryParticipantContact.LastName.replace('\'', '').replace('-', '');

                                    Boolean firstname_lastname_match =
                                        participant_firstname_sanitized.containsIgnoreCase(jsoninput_firstname_sanitized) &&
                                        participant_lastname_sanitized.containsIgnoreCase(jsoninput_lastname_sanitized);
                                    if (birthdate == participant.PrimaryParticipantContact.Birthdate || firstname_lastname_match) {
                                        clm.ARC_MemberContact__c = participant.PrimaryParticipantContactId;
                                        clm.ARC_ParticipantPolicyParticipant__c = participant.Id;
                                        clm.ARC_PatientCensusMember__c = participant.PrimaryParticipantContact.ARC_CensusMember__c;
                                    }

                                    if (participant.Role == 'Primary') {
                                        clm.ARC_Primary_Member__c = participant.PrimaryParticipantContactId;
                                        clm.ARC_PrimaryMemberCM__c = participant.PrimaryParticipantContact.ARC_CensusMember__c;
                                    }
                                }

                                break;
                            }
                        }

                        if (
                            (found_valid_policy == false) &&
                            (patient_policies_list.isEmpty() == false &&
                            found_active_contract == false) || // Check if all policies are terminated or voided, then take the last to assign the patient and member contact.
                            (patient_policies_list.size() == 1 &&
                            patient_policies_list[0].ARC_Contract__r?.ARC_ContractReason__c == 'Add Newborn') // Check if Add Newborn
                        ) {
                            InsurancePolicy most_recent_policy = patient_policies_list[0]; // Most recent policy
                            for (InsurancePolicyParticipant participant : most_recent_policy.InsurancePolicyParticipants) {
                                String participant_firstname_sanitized = participant.PrimaryParticipantContact.FirstName.replace('\'', '').replace('-', '');
                                String participant_lastname_sanitized = participant.PrimaryParticipantContact.LastName.replace('\'', '').replace('-', '');

                                Boolean firstname_lastname_match =
                                    participant_firstname_sanitized.containsIgnoreCase(jsoninput_firstname_sanitized) &&
                                    participant_lastname_sanitized.containsIgnoreCase(jsoninput_lastname_sanitized);
                                if (birthdate == participant.PrimaryParticipantContact.Birthdate || firstname_lastname_match) {
                                    clm.ARC_MemberContact__c = participant.PrimaryParticipantContactId;
                                    clm.ARC_ParticipantPolicyParticipant__c = participant.Id;
                                    clm.ARC_PatientCensusMember__c = participant.PrimaryParticipantContact.ARC_CensusMember__c;
                                }

                                if (participant.Role == 'Primary') {
                                    clm.ARC_Primary_Member__c = participant.PrimaryParticipantContactId;
                                    clm.ARC_PrimaryMemberCM__c = participant.PrimaryParticipantContact.ARC_CensusMember__c;
                                }
                            }
                        }
                        
                        // Right before the CREATE LINE ITEMS section, extract Medicare payer ID
                        String medicarePayerId = null;
                        
                        List<Object> otherSubscriberInfo = (List<Object>)clmInformation.get('otherSubscriberInfo');
                        if (otherSubscriberInfo != null && !otherSubscriberInfo.isEmpty()) {
                            for (Object subscriber : otherSubscriberInfo) {
                                Map<String, Object> subInfo = (Map<String, Object>)subscriber;
                                String filingCode = (String)subInfo.get('ClaimFilingIndicatorCode');
                                
                                if (isMedicareFilingCode(filingCode)) {
                                    medicarePayerId = (String)subInfo.get('PayerID');
                                    break;
                                }
                            }
                        }
						
                        // CREATE LINE ITEMS
                        for (Object itm : lineItems) {
                            Map<String, Object> item = (Map<String, Object>) itm;
                            ClaimCoveragePaymentDetail lineItem = new ClaimCoveragePaymentDetail();

                            lineItem.Name = (String) item.get('ServiceLineNumber.AssignedNumber_01');
                            lineItem.ARC_ProcedureCode__c = codeName_codeId.get((String) item.get('CompositeMedicalProcedureIdentifier.ProcedureCode_02'));
                            lineItem.ARC_Allowed__c = item.get('LinePricing_RepricingInformation.RepricedAllowedAmount_02') != null
                                ? Double.valueOf(item.get('LinePricing_RepricingInformation.RepricedAllowedAmount_02'))
                                : null;
                            lineItem.ARC_Claim__c = clm.Id;
                            lineItem.ClaimCoverageId = claimId_CovId.get(clm.Id);
                            lineItem.Status = 'New';
                            lineItem.ARC_Mod1__c = (String) item.get('CompositeMedicalProcedureIdentifier.ProcedureModifier_03');
                            lineItem.ARC_Mod2__c = (String) item.get('CompositeMedicalProcedureIdentifier.ProcedureModifier_04');
                            lineItem.ARC_Mod3__c = (String) item.get('CompositeMedicalProcedureIdentifier.ProcedureModifier_05');
                            lineItem.ARC_Mod4__c = (String) item.get('CompositeMedicalProcedureIdentifier.ProcedureModifier_06');
                            if ((String) item.get('CompositeMedicalProcedureIdentifier.ProcedureCode_02') != null)
                                cCToCompare.add((String) item.get('CompositeMedicalProcedureIdentifier.ProcedureCode_02'));

                            // CHECK IF ARE FIELDS FROM PROFESSIONAL OR INSTITUTIONAL
                            if ((Boolean) clmJson.get('professional')) {
                                lineItem.ClaimedAmount = Double.valueOf((String) item.get('ProfessionalService.LineItemChargeAmount_02'));
                                // MCR BILLED AMT - equals LineItemChargeAmount_02 from loop 2400
                                lineItem.Medicare_Billed__c = Decimal.valueOf((String) item.get('ProfessionalService.LineItemChargeAmount_02'));
                                lineItem.RecordTypeId = rtLineProf;
                                lineItem.ARC_Quantity__c = Double.valueOf(item.get('ProfessionalService.ServiceUnitCount_04'));
                                lineItem.ARC_FreqType__c = (String) item.get('ProfessionalService.UnitorBasisforMeasurementCode_03');
                                lineItem.ARC_PlaceofService__c = (String) item.get('ProfessionalService.PlaceofServiceCode_05') != null
                                    ? (String) item.get('ProfessionalService.PlaceofServiceCode_05')
                                    : clm.ARC_PlaceofService__c;

                                // DATE OF SERVICE
                                List<String> dates = String.valueOf((String) item.get('ServiceDate.DateTimePeriod_03')).split('-');
                                lineItem.ARC_DateOfService__c = formatDate(dates[0]);

                                // CONVERT CODE POINTERS FROM NUMBERS TO LETTERS
                                lineItem.ICD_Codes__c = convertPointerToLetters(
                                    (String) item.get('CompositeDiagnosisCodePointer.DiagnosisCodePointer_01'),
                                    (String) item.get('CompositeDiagnosisCodePointer.DiagnosisCodePointer_02'),
                                    (String) item.get('CompositeDiagnosisCodePointer.DiagnosisCodePointer_03'),
                                    (String) item.get('CompositeDiagnosisCodePointer.DiagnosisCodePointer_04')
                                );
                            } else if ((Boolean) clmJson.get('institutional')) {
                                lineItem.ClaimedAmount = Double.valueOf((String) item.get('InstitutionalServiceLine.LineItemChargeAmount_03'));
                                // MCR BILLED AMT - equals LineItemChargeAmount_03 from loop 2400 (institutional)
                                lineItem.Medicare_Billed__c = Decimal.valueOf((String) item.get('InstitutionalServiceLine.LineItemChargeAmount_03'));
                                lineItem.RecordTypeId = rtLineInst;
                                lineItem.ARC_Quantity__c = Integer.valueOf(item.get('InstitutionalServiceLine.ServiceUnitCount_05'));
                                lineItem.ARC_FreqType__c = (String) item.get('InstitutionalServiceLine.UnitorBasisforMeasurementCode_04');
                                lineItem.ARC_RevenueCode__c = (String) item.get('InstitutionalServiceLine.ServiceLineRevenueCode_01');
                                lineItem.ARC_PlaceofService__c = clm.ARC_PlaceofService__c;

                                // DATE OF SERVICE
                                if (item.get('ServiceDate.DateTimePeriod_03') != null) {
                                    List<String> dates = String.valueOf((String) item.get('ServiceDate.DateTimePeriod_03')).split('-');
                                    if (dates.size() == 2) {
                                        lineItem.ARC_DOSFrom__c = formatDate(dates[0]);
                                        lineItem.ARC_DOSTo__c = formatDate(dates[1]);
                                    } else if (dates.size() == 1) {
                                        lineItem.ARC_DOSFrom__c = formatDate(dates[0]);
                                        lineItem.ARC_DOSTo__c = formatDate(dates[0]);
                                    }
                                } else {
                                    lineItem.ARC_DOSFrom__c = clm.ARC_DOSFrom__c;
                                    lineItem.ARC_DOSTo__c = clm.ARC_DOSTo__c;
                                }
                            }
							
                            // Extract Medicare adjudication data from Loop2430
                            // Only process if we found a Medicare payer at claim level
                            if (medicarePayerId != null) {
                                List<Object> lineAdjudication = (List<Object>)item.get('otherPayerLineAdjudication');
                                if (lineAdjudication != null && !lineAdjudication.isEmpty()) {
                                    
                                    // Find the adjudication that matches Medicare payer ID
                                    for (Object adj : lineAdjudication) {
                                        Map<String, Object> adjMap = (Map<String, Object>)adj;
                                        String payerId = (String)adjMap.get('OtherPayerID');
                                        
                                        if (medicarePayerId.equals(payerId)) {
                                            // This is Medicare - extract the values
                                            
                                            // MCR PAID AMT - ServiceLinePaidAmount_02 from loop 2430
                                            String medicarePaidStr = (String)adjMap.get('LinePaidAmount');
                                            if (String.isNotBlank(medicarePaidStr)) {
                                                lineItem.Medicare_Paid__c = Decimal.valueOf(medicarePaidStr);
                                            } else {
                                                lineItem.Medicare_Paid__c = 0;
                                            }
                                            
                                            // MCR Member Liability - PR adjustments only
                                            String memberLiabilityStr = (String)adjMap.get('MemberLiability');
                                            if (String.isNotBlank(memberLiabilityStr)) {
                                                lineItem.Medicare_Member_Liability__c = Decimal.valueOf(memberLiabilityStr);
                                            } else {
                                                lineItem.Medicare_Member_Liability__c = 0;
                                            }
                                            
                                            // Get CO45 adjustment for Medicare Allowed calculation
                                            String co45AdjustmentStr = (String)adjMap.get('CO45Adjustment');
                                            Decimal co45Adjustment = 0;
                                            if (String.isNotBlank(co45AdjustmentStr)) {
                                                co45Adjustment = Decimal.valueOf(co45AdjustmentStr);
                                            }

                                            // MCR ALLOWED AMT = MCR BILLED AMT minus CO45 adjustment
                                            if (lineItem.Medicare_Billed__c != null) {
                                                lineItem.Medicare_Allowed__c = lineItem.Medicare_Billed__c - co45Adjustment;
                                            } else {
                                                lineItem.Medicare_Allowed__c = 0;
                                            }
                                            
                                            // Medicare Adjusted - sum of non-PR adjustments
                                            String medicareAdjustedStr = (String)adjMap.get('MedicareAdjusted');
                                            if (String.isNotBlank(medicareAdjustedStr)) {
                                                lineItem.Medicare_Adjusted__c = Decimal.valueOf(medicareAdjustedStr);
                                            } else {
                                                lineItem.Medicare_Adjusted__c = 0;
                                            }
                                            
                                            // Map Medicare Coinsurance amount (keeping for backward compatibility)
                                            String medicareCoinsuranceStr = (String)adjMap.get('MedicareCoinsurance');
                                            if (String.isNotBlank(medicareCoinsuranceStr)) {
                                                lineItem.Medicare_Coinsurance__c = Decimal.valueOf(medicareCoinsuranceStr);
                                            } else {
                                                lineItem.Medicare_Coinsurance__c = 0;
                                            }

                                            // For legacy claims (Medicare as secondary), populate ARC_Allowed__c from Medicare_Member_Liability__c
                                            // This ensures the allowed amount reflects what the member is responsible for after Medicare
                                            if (lineItem.ARC_Allowed__c == null && lineItem.Medicare_Member_Liability__c != null) {
                                                lineItem.ARC_Allowed__c = lineItem.Medicare_Member_Liability__c;
                                            }
                                            
                                            break; // Found Medicare, no need to check other payers
                                        }
                                    }
                                }
                            }
                            
                            upsertListClaimItem.add(lineItem);
                        }

                        // CLAIM AUXILIARY FIELDS
                        clm.ARC_CCToCompare__c = String.join(cCToCompare, ';');
                        ci.ARC_Status__c = 'Success';
                        if (clm.ARC_NTE837IBNoteSegment__c.contains('#HG6')) {
                            clm.Name = clm.Name + ' QWICKPAY';
                            clm.ARC_QwikPay__c = true;
                        }

                        mappingWorking3.add(clm);
                        upsertListClaim.add(clm);
                    } catch (Exception err) {
                        // Update status of the claim
                        System.debug('3rd catch');
                        clm.Status = 'Mapping Failed';
                        mappingFailed.add(clm);

                        ci.ARC_Status__c = 'Failed';

                        // Prepare email content
                        String exceptionMessage = err.getMessage();
                        String exceptionStackTrace = err.getStackTraceString();
                        System.debug(exceptionMessage);
                        System.debug(exceptionStackTrace);

                        // Create the email
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new List<String>{ 'agustin.garay@arcsona.com', 'ignacio.ferreiro@arcsona.com' });
                        mail.setSubject('Exception Occurred in Apex Code');

                        // Email body with exception message and stack trace
                        String body = 'An exception occurred during the execution of the code.\n\n';
                        body += 'Exception Message: ' + exceptionMessage + '\n';
                        body += 'Stack Trace: ' + exceptionStackTrace + '\n';

                        mail.setPlainTextBody(body);

                        // Send the email
                        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
                    }
                }
            }
        }
        upsertListClaim.addAll(mappingFailed);
        upsert upsertListClaimItem; // INSERT FIRST THE LINE ITEMS FOR THE AUTO ADJUDICATION FLOW FOR QWICK PAY SMBs
        upsert upsertListClaim;
        insert upsertListClaimCode2;
        insert upsertListClaimCode;
        update inputClaims;

        Set<Id> claimIds = new Set<Id>();
        for (SObject claim : upsertListClaim) {
            claimIds.add(claim.Id);
        }

        List<Claim> claims_with_preauthnumbers_field = [SELECT Id, PA_Number_Formatted__c FROM Claim WHERE Id IN :claimIds];
        Set<String> preauth_numbers = new Set<String>();
        for (Claim claim : claims_with_preauthnumbers_field) {
            if (String.isNotBlank(claim.PA_Number_Formatted__c)) {
                preauth_numbers.add(claim.PA_Number_Formatted__c);
            }
        }

        List<Case> preauth_cases = [SELECT Id, HealthCloudGA__SourceSystemID__c FROM Case WHERE RecordType.Name = 'Authorization' AND HealthCloudGA__SourceSystemID__c IN :preauth_numbers];

        for (Claim claim : claims_with_preauthnumbers_field) {
            for (Case preauth_case : preauth_cases) {
                if (claim.PA_Number_Formatted__c.equalsIgnoreCase(preauth_case.HealthCloudGA__SourceSystemID__c)) {
                    claim.ARC_PriorAuthorizationCase__c = preauth_case.Id;
                }
            }
        }

        upsert claims_with_preauthnumbers_field;

        // RETURN METHOD
        Set<Id> returnedClaims = new Set<Id>();
        for (Claim clm : mappingWorking3)
            returnedClaims.add(clm.Id);
        return returnedClaims;
    }

    // returns a rank for the conditions to match a GroupCensusMember with the information from the JsonInput for a claim 
    private static Integer calculateMatchScore(Boolean firstname, Boolean lastname, Boolean dob, Boolean memberId, Boolean street, Boolean city, Boolean state) {
        if (firstname && lastname && dob && memberId) {
            return 100;
        } else if (lastname && dob && memberId) {
            return 90;
        } else if ((firstname && lastname && dob) && (street || city || state)) {
            return 80;
        } else if ((firstname && (lastname || dob ) ) && (street && city && state)) {
            return 70;
        }
        return -1; // No match
    }

    public static String convertPointerToLetters(String point1, String point2, String point3, String point4) {
        List<String> pointers = new List<String>{ point1, point2, point3, point4 };
        String output = '';
        Integer counter = 0;

        for (String point : pointers) {
            switch on point {
                when '1' {
                    if (counter == 0) {
                        output = 'A';
                    } else {
                        output += ', A';
                    }
                }
                when '2' {
                    if (counter == 0) {
                        output = 'B';
                    } else {
                        output += ', B';
                    }
                }
                when '3' {
                    if (counter == 0) {
                        output = 'C';
                    } else {
                        output += ', C';
                    }
                }
                when '4' {
                    if (counter == 0) {
                        output = 'D';
                    } else {
                        output += ', D';
                    }
                }
                when '5' {
                    if (counter == 0) {
                        output = 'E';
                    } else {
                        output += ', E';
                    }
                }
                when '6' {
                    if (counter == 0) {
                        output = 'F';
                    } else {
                        output += ', F';
                    }
                }
                when '7' {
                    if (counter == 0) {
                        output = 'G';
                    } else {
                        output += ', G';
                    }
                }
                when '8' {
                    if (counter == 0) {
                        output = 'H';
                    } else {
                        output += ', H';
                    }
                }
                when '9' {
                    if (counter == 0) {
                        output = 'I';
                    } else {
                        output += ', I';
                    }
                }
                when '10' {
                    if (counter == 0) {
                        output = 'J';
                    } else {
                        output += ', J';
                    }
                }
                when '11' {
                    if (counter == 0) {
                        output = 'K';
                    } else {
                        output += ', K';
                    }
                }
                when '12' {
                    if (counter == 0) {
                        output = 'L';
                    } else {
                        output += ', L';
                    }
                }
            }

            counter++;
        }

        return output;
    }

    public static ARC_Institutional_Claim_Code__c createClaimCode(Map<String, Object> inputMap) {
        String codeDate = (String) inputMap.get('date');
        String claimId = (String) inputMap.get('claimId');
        String occurenceInformationCode = (String) inputMap.get('occurenceInformationCode');
        String valueInformationCode = (String) inputMap.get('valueInformationCode');
        String POA = (String) inputMap.get('POA');
        Id recordTypeId = (Id) inputMap.get('recordType');
        Id otherDiagnosisCode = (Id) inputMap.get('otherDiagnosisCode');
        Id eCode = (Id) inputMap.get('eCode');
        Id otherProcedureId = (Id) inputMap.get('otherProcedureId');
        Id conditionCode = (Id) inputMap.get('conditionCode');
        Decimal valueAmount = (String) inputMap.get('valueAmount') != null ? Decimal.valueOf((String) inputMap.get('valueAmount')) : null;

        ARC_Institutional_Claim_Code__c claimCode = new ARC_Institutional_Claim_Code__c();
        if (codeDate != null) {
            claimCode.ARC_Date__c = formatDate(codeDate);
        }

        claimCode.ARC_Institutional_Claim__c = claimId;
        claimCode.RecordTypeId = recordTypeId;
        claimCode.ARC_Other_Procedure_Code__c = otherProcedureId;
        claimCode.ARC_Occurrence_Code__c = occurenceInformationCode;
        claimCode.ARC_Vale_Codes__c = valueInformationCode;
        claimCode.ARC_Amount__c = valueAmount;
        claimCode.ARC_POA__c = POA;
        claimCode.ARC_ICD_DX__c = otherDiagnosisCode;
        claimCode.ARC_ConditionCode__c = conditionCode;
        claimCode.ARC_ECode__c = eCode;

        return claimCode;
    }

    public static Date formatDate(String inputDate) {
        if (inputDate != null) {
            Integer year = Integer.valueOf(inputDate.substring(0, 1) + inputDate.substring(1, 2) + inputDate.substring(2, 3) + inputDate.substring(3, 4));
            Integer month = Integer.valueOf(inputDate.substring(4, 5) + inputDate.substring(5, 6));
            Integer day = Integer.valueOf(inputDate.substring(6, 7) + inputDate.substring(7, 8));
            return date.newInstance(year, month, day);
        } else {
            return null;
        }
    }

    public static String parseCode(String code) {
        if (code.length() > 3) {
            return code.left(3) + '.' + code.right(code.length() - 3);
        } else {
            return code;
        }
    }

    public static String createPlaceOfService(String billType) {
        String inpatientBillTypes = System.Label.ARC_Inpatient_Bill_Types;
        String outpatientBillTypes = System.Label.ARC_Outpatient_Bill_Types;

        List<String> inpList = inpatientBillTypes.split(';');
        List<String> outList = outpatientBillTypes.split(';');

        if (inpList.contains(billType)) {
            return '21';
        } else if (outList.contains(billType)) {
            return '22';
        } else {
            return billType;
        }
    }
    
    // Captures all of the possible medicare filing codes for Optum Claims
    private static Boolean isMedicareFilingCode(String filingCode) {
        Set<String> medicareFilingCodes = new Set<String>{
            'MA',  // Medicare Part A
            'MB',  // Medicare Part B  
            'MC',  // Medicare Part C (Medicare Advantage)
            'MD',  // Medicare Part D (Prescription Drug Coverage)
            '12',  // Medicare Secondary Working Aged Beneficiary or Spouse with Employer Group Health Plan
            '13',  // Medicare Secondary End-Stage Renal Disease Beneficiary in the Mandated Coordination Period
            '14',  // Medicare Secondary, No-fault Insurance including Auto is Primary
            '15',  // Medicare Secondary Workers' Compensation
            '16',  // Medicare Secondary Public Health Service (PHS) or Other Federal Agency
            '41',  // Medicare Secondary Black Lung
            '42',  // Medicare Secondary Veteran's Administration
            '43',  // Medicare Secondary Disabled Beneficiary Under Age 65 with Large Group Health Plan (LGHP)
            '47'   // Medicare Secondary, Other Liability Insurance is Primary
        };
        
        return medicareFilingCodes.contains(filingCode);
    }
    
}