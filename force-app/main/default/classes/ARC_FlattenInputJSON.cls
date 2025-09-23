public with sharing class ARC_FlattenInputJSON {

    public static List<Object> flattenJSON(ARC_ClaimInput__c inputClaim, String clmRecordType) {        
        List<Object> output = new List<Object>();
        
        Map<String, Object> parentNode = (Map<String, Object>)JSON.deserializeUntyped(inputClaim.ARC_InputJSON__c);
        // Groups
        List<Object> Groups = (List<Object>)parentNode.get('Groups');

        for (Object itemGroup : Groups) {
            Map<String, Object> groupMap = (Map<String, Object>)itemGroup;

            // Groups.Transactions
            List<Object> Transactions = (List<Object>)groupMap.get('Transactions');
            for (Object itemTransaction : Transactions) {
                Map<String, Object> outputMap = new Map<String, Object>();

                Map<String, Object> objSubmitter = new Map<String, Object>();
                Map<String, Object> objBillingProvider = new Map<String, Object>();
                Map<String, Object> objAttendingProvider = new Map<String, Object>();
                Map<String, Object> objSubscriberInformation = new Map<String, Object>();
                Map<String, Object> objPatientInformation = new Map<String, Object>();
                Map<String, Object> objClaimInformation = new Map<String, Object>();
                Map<String, Object> objServiceFacility = new Map<String, Object>();
                Map<String, Object> objReferringProvider = new Map<String, Object>();
                Map<String, Object> objRenderingProvider = new Map<String, Object>();
                List<Object> claimLineItemsList = new List<Object>();
                
                Map<String, Object> transactionsMap = (Map<String, Object>)itemTransaction;
                // Groups.Transactions.AllNM1
                Map<String, Object> ST = (Map<String, Object>)transactionsMap.get('ST');
                outputMap.put('TransactionSetControlNumber', (String)ST.get('TransactionSetControlNumber_02'));

                Map<String, Object> AllNM1 = (Map<String, Object>)transactionsMap.get('AllNM1');
                // Groups.Transactions.AllNM1.Loop1000A
                Map<String, Object> Loop1000A = (Map<String, Object>)AllNM1.get('Loop1000A');
                Map<String, Object> NM1_SubmitterName = (Map<String, Object>)Loop1000A.get('NM1_SubmitterName');
                objSubmitter.put('SubmitterName.EntityIdentifierCode_01', (String)NM1_SubmitterName.get('EntityIdentifierCode_01'));
                objSubmitter.put('SubmitterName.EntityTypeQualifier_02', (String)NM1_SubmitterName.get('EntityTypeQualifier_02'));
                objSubmitter.put('SubmitterName.ResponseContactLastorOrganizationName_03', (String)NM1_SubmitterName.get('ResponseContactLastorOrganizationName_03'));
                objSubmitter.put('SubmitterName.IdentificationCodeQualifier_08', (String)NM1_SubmitterName.get('IdentificationCodeQualifier_08'));
                objSubmitter.put('SubmitterName.ResponseContactFirstName_04', (String)NM1_SubmitterName.get('ResponseContactFirstName_04'));
                objSubmitter.put('SubmitterName.ResponseContactMiddleName_05', (String)NM1_SubmitterName.get('ResponseContactMiddleName_05'));
                objSubmitter.put('SubmitterName.NamePrefix_06', (String)NM1_SubmitterName.get('NamePrefix_06'));
                objSubmitter.put('SubmitterName.ResponseContactNameSuffix_07', (String)NM1_SubmitterName.get('ResponseContactNameSuffix_07'));
                objSubmitter.put('SubmitterName.EntityRelationshipCode_10', (String)NM1_SubmitterName.get('EntityRelationshipCode_10'));
                objSubmitter.put('SubmitterName.EntityIdentifierCode_11', (String)NM1_SubmitterName.get('EntityIdentifierCode_11'));
                objSubmitter.put('SubmitterName.NameLastorOrganizationName_12', (String)NM1_SubmitterName.get('NameLastorOrganizationName_12'));
                objSubmitter.put('SubmitterName.ResponseContactIdentifier_09', (String)NM1_SubmitterName.get('ResponseContactIdentifier_09'));
                outputMap.put('submitterNPI', (String)NM1_SubmitterName.get('ResponseContactIdentifier_09'));

                List<Object> PER_SubmitterEDIContactInformation = (List<Object>)Loop1000A.get('PER_SubmitterEDIContactInformation');
                for (Object itemPER_SubmitterEDIContactInformation : PER_SubmitterEDIContactInformation) {
                    Map<String, Object> loopMap = (Map<String, Object>)itemPER_SubmitterEDIContactInformation;

                    objSubmitter.put('SubmitterEDIContactInformation.ContactFunctionCode_01', (String)loopMap.get('ContactFunctionCode_01'));
                    objSubmitter.put('SubmitterEDIContactInformation.ResponseContactName_02', (String)loopMap.get('ResponseContactName_02'));
                    objSubmitter.put('SubmitterEDIContactInformation.CommunicationNumberQualifier_03', (String)loopMap.get('CommunicationNumberQualifier_03'));
                    objSubmitter.put('SubmitterEDIContactInformation.ResponseContactCommunicationNumber_04', (String)loopMap.get('ResponseContactCommunicationNumber_04'));
                    objSubmitter.put('SubmitterEDIContactInformation.CommunicationNumberQualifier_05', (String)loopMap.get('CommunicationNumberQualifier_05'));
                    objSubmitter.put('SubmitterEDIContactInformation.ResponseContactCommunicationNumber_06', (String)loopMap.get('ResponseContactCommunicationNumber_06'));
                    objSubmitter.put('SubmitterEDIContactInformation.CommunicationNumberQualifier_07', (String)loopMap.get('CommunicationNumberQualifier_07'));
                    objSubmitter.put('SubmitterEDIContactInformation.ResponseContactCommunicationNumber_08', (String)loopMap.get('ResponseContactCommunicationNumber_08'));
                    objSubmitter.put('SubmitterEDIContactInformation.ContactInquiryReference_09', (String)loopMap.get('ContactInquiryReference_09'));
                }
                
                // Groups.Transactions.Loop2000A
                List<Object> Loop2000A = (List<Object>)transactionsMap.get('Loop2000A');
                for (Object itemLoop2000A : Loop2000A) {
                    Map<String, Object> loopMap = (Map<String, Object>)itemLoop2000A;
                    
                    // Groups.Transactions.Loop2000A.HL_BillingProviderHierarchicalLevel
                    Map<String, Object> HL_BillingProviderHierarchicalLevel = (Map<String, Object>)loopMap.get('HL_BillingProviderHierarchicalLevel');
                    objBillingProvider.put('BillingProviderHierarchicalLevel.HierarchicalIDNumber_01', (String)HL_BillingProviderHierarchicalLevel.get('HierarchicalIDNumber_01'));
                    objBillingProvider.put('BillingProviderHierarchicalLevel.HierarchicalParentIDNumber_02', (String)HL_BillingProviderHierarchicalLevel.get('HierarchicalParentIDNumber_02'));
                    objBillingProvider.put('BillingProviderHierarchicalLevel.HierarchicalLevelCode_03', (String)HL_BillingProviderHierarchicalLevel.get('HierarchicalLevelCode_03'));
                    objBillingProvider.put('BillingProviderHierarchicalLevel.HierarchicalChildCode_04', (String)HL_BillingProviderHierarchicalLevel.get('HierarchicalChildCode_04'));

                    // Groups.Transactions.Loop2000A.PRV_BillingProviderSpecialtyInformation
                    Map<String, Object> PRV_BillingProviderSpecialtyInformation = (Map<String, Object>)loopMap.get('PRV_BillingProviderSpecialtyInformation');
                    if (PRV_BillingProviderSpecialtyInformation != null) {
                        objBillingProvider.put('BillingProviderSpecialtyInformation.ProviderCode_01', (String)PRV_BillingProviderSpecialtyInformation.get('ProviderCode_01'));
                        objBillingProvider.put('BillingProviderSpecialtyInformation.ReferenceIdentificationQualifier_02', (String)PRV_BillingProviderSpecialtyInformation.get('ReferenceIdentificationQualifier_02'));
                        objBillingProvider.put('BillingProviderSpecialtyInformation.ProviderTaxonomyCode_03', (String)PRV_BillingProviderSpecialtyInformation.get('ProviderTaxonomyCode_03'));
                        objBillingProvider.put('BillingProviderSpecialtyInformation.StateorProvinceCode_04', (String)PRV_BillingProviderSpecialtyInformation.get('StateorProvinceCode_04'));
                        objBillingProvider.put('BillingProviderSpecialtyInformation.ProviderSpecialtyInformation_05', (String)PRV_BillingProviderSpecialtyInformation.get('ProviderSpecialtyInformation_05'));
                        objBillingProvider.put('BillingProviderSpecialtyInformation.ProviderOrganizationCode_06', (String)PRV_BillingProviderSpecialtyInformation.get('ProviderOrganizationCode_06'));
                    }

                    // Groups.Transactions.Loop2000A.AllNM1
                    Map<String, Object> AllNM1_2 = (Map<String, Object>)loopMap.get('AllNM1');
                    // Groups.Transactions.Loop2000A.AllNM1.Loop2010AA
                    Map<String, Object> Loop2010AA = (Map<String, Object>)AllNM1_2.get('Loop2010AA');
                    Map<String, Object> NM1_BillingProviderName = (Map<String, Object>)Loop2010AA.get('NM1_BillingProviderName');
                    objBillingProvider.put('BillingProviderName.EntityIdentifierCode_01', (String)NM1_BillingProviderName.get('EntityIdentifierCode_01'));
                    objBillingProvider.put('BillingProviderName.EntityTypeQualifier_02', (String)NM1_BillingProviderName.get('EntityTypeQualifier_02'));
                    objBillingProvider.put('BillingProviderName.ResponseContactLastorOrganizationName_03', (String)NM1_BillingProviderName.get('ResponseContactLastorOrganizationName_03'));
                    objBillingProvider.put('BillingProviderName.ResponseContactFirstName_04', (String)NM1_BillingProviderName.get('ResponseContactFirstName_04'));
                    objBillingProvider.put('BillingProviderName.ResponseContactMiddleName_05', (String)NM1_BillingProviderName.get('ResponseContactMiddleName_05'));
                    objBillingProvider.put('BillingProviderName.NamePrefix_06', (String)NM1_BillingProviderName.get('NamePrefix_06'));
                    objBillingProvider.put('BillingProviderName.ResponseContactNameSuffix_07', (String)NM1_BillingProviderName.get('ResponseContactNameSuffix_07'));
                    objBillingProvider.put('BillingProviderName.IdentificationCodeQualifier_08', (String)NM1_BillingProviderName.get('IdentificationCodeQualifier_08'));
                    objBillingProvider.put('BillingProviderName.EntityRelationshipCode_10', (String)NM1_BillingProviderName.get('EntityRelationshipCode_10'));
                    objBillingProvider.put('BillingProviderName.EntityIdentifierCode_11', (String)NM1_BillingProviderName.get('EntityIdentifierCode_11'));
                    objBillingProvider.put('BillingProviderName.NameLastorOrganizationName_12', (String)NM1_BillingProviderName.get('NameLastorOrganizationName_12'));
                    objBillingProvider.put('BillingProviderName.ResponseContactIdentifier_09', (String)NM1_BillingProviderName.get('ResponseContactIdentifier_09'));
                    outputMap.put('billingProviderNPI', (String)NM1_BillingProviderName.get('ResponseContactIdentifier_09'));
                    
                    Map<String, Object> N3_BillingProviderAddress = (Map<String, Object>)Loop2010AA.get('N3_BillingProviderAddress');
                    objBillingProvider.put('BillingProviderAddress.ResponseContactAddressLine_01', (String)N3_BillingProviderAddress.get('ResponseContactAddressLine_01'));
                    objBillingProvider.put('BillingProviderAddress.ResponseContactAddressLine_02', (String)N3_BillingProviderAddress.get('ResponseContactAddressLine_02'));

                    Map<String, Object> N4_BillingProviderCity_State_ZIPCode = (Map<String, Object>)Loop2010AA.get('N4_BillingProviderCity_State_ZIPCode');
                    objBillingProvider.put('BillingProviderCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01', (String)N4_BillingProviderCity_State_ZIPCode.get('AdditionalPatientInformationContactCityName_01'));
                    objBillingProvider.put('BillingProviderCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02', (String)N4_BillingProviderCity_State_ZIPCode.get('AdditionalPatientInformationContactStateCode_02'));
                    objBillingProvider.put('BillingProviderCity_State_ZIPCode.AdditionalPatientInformationContactPostalZoneorZIPCode_03', (String)N4_BillingProviderCity_State_ZIPCode.get('AdditionalPatientInformationContactPostalZoneorZIPCode_03'));
                    objBillingProvider.put('BillingProviderCity_State_ZIPCode.CountryCode_04', (String)N4_BillingProviderCity_State_ZIPCode.get('CountryCode_04'));
                    objBillingProvider.put('BillingProviderCity_State_ZIPCode.LocationQualifier_05', (String)N4_BillingProviderCity_State_ZIPCode.get('LocationQualifier_05'));
                    objBillingProvider.put('BillingProviderCity_State_ZIPCode.LocationIdentifier_06', (String)N4_BillingProviderCity_State_ZIPCode.get('LocationIdentifier_06'));
                    objBillingProvider.put('BillingProviderCity_State_ZIPCode.CountrySubdivisionCode_07', (String)N4_BillingProviderCity_State_ZIPCode.get('CountrySubdivisionCode_07'));

                    Map<String, Object> Loop2010AB = (Map<String, Object>)AllNM1_2.get('Loop2010AB');
                    if (Loop2010AB != null) {
                        Map<String, Object> N3_Pay_ToAddress_ADDRESS = (Map<String, Object>)Loop2010AB.get('N3_Pay_ToAddress_ADDRESS');
                        if (N3_Pay_ToAddress_ADDRESS != null) {
                            objBillingProvider.put('PayToAddress.ResponseContactAddressLine_01', (String)N3_Pay_ToAddress_ADDRESS.get('ResponseContactAddressLine_01'));
                        }
                        Map<String, Object> N4_Pay_AddressCity_State_ZIPCode = (Map<String, Object>)Loop2010AB.get('N4_Pay_AddressCity_State_ZIPCode');
                        if (N4_Pay_AddressCity_State_ZIPCode != null) {
                           objBillingProvider.put('PayToAddress.AdditionalPatientInformationContactCityName_01', (String)N4_Pay_AddressCity_State_ZIPCode.get('AdditionalPatientInformationContactCityName_01')); 
                           objBillingProvider.put('PayToAddress.AdditionalPatientInformationContactStateCode_02', (String)N4_Pay_AddressCity_State_ZIPCode.get('AdditionalPatientInformationContactStateCode_02')); 
                           objBillingProvider.put('PayToAddress.AdditionalPatientInformationContactPostalZoneorZIPCode_03', (String)N4_Pay_AddressCity_State_ZIPCode.get('AdditionalPatientInformationContactPostalZoneorZIPCode_03')); 
                        }
                    }

                    if (clmRecordType == 'Professional') {
                        Map<String, Object> AllREF = (Map<String, Object>)Loop2010AA.get('AllREF');
                        if (AllREF != null) {
                            Map<String, Object> REF_BillingProviderTaxIdentification = (Map<String, Object>)AllREF.get('REF_BillingProviderTaxIdentification');
                            if (REF_BillingProviderTaxIdentification != null) {
                                objBillingProvider.put('BillingProviderTaxIdentification.ReferenceIdentificationQualifier_01', (String)REF_BillingProviderTaxIdentification.get('ReferenceIdentificationQualifier_01'));
                                objBillingProvider.put('BillingProviderTaxIdentification.MemberGrouporPolicyNumber_02', (String)REF_BillingProviderTaxIdentification.get('MemberGrouporPolicyNumber_02'));
                                objBillingProvider.put('BillingProviderTaxIdentification.Description_03', (String)REF_BillingProviderTaxIdentification.get('Description_03'));
                                objBillingProvider.put('BillingProviderTaxIdentification.ReferenceIdentifier_04', (String)REF_BillingProviderTaxIdentification.get('ReferenceIdentifier_04'));
                            }
                        }
                    }

                    List<Object> PER_BillingProviderContactInformation = (List<Object>)Loop2010AA.get('PER_BillingProviderContactInformation');
                    if (PER_BillingProviderContactInformation != null) {
                        for (Object itemPER_BillingProviderContactInformation : PER_BillingProviderContactInformation) {
                            Map<String, Object> loopMap2 = (Map<String, Object>)itemPER_BillingProviderContactInformation;
                            
                            objBillingProvider.put('BillingProviderContactInformation.ContactFunctionCode_01', (String)loopMap2.get('ContactFunctionCode_01'));
                            objBillingProvider.put('BillingProviderContactInformation.ResponseContactName_02', (String)loopMap2.get('ResponseContactName_02'));
                            objBillingProvider.put('BillingProviderContactInformation.CommunicationNumberQualifier_03', (String)loopMap2.get('CommunicationNumberQualifier_03'));
                            objBillingProvider.put('BillingProviderContactInformation.ResponseContactCommunicationNumber_04', (String)loopMap2.get('ResponseContactCommunicationNumber_04'));
                            objBillingProvider.put('BillingProviderContactInformation.CommunicationNumberQualifier_05', (String)loopMap2.get('CommunicationNumberQualifier_05'));
                            objBillingProvider.put('BillingProviderContactInformation.ResponseContactCommunicationNumber_06', (String)loopMap2.get('ResponseContactCommunicationNumber_06'));
                            objBillingProvider.put('BillingProviderContactInformation.CommunicationNumberQualifier_07', (String)loopMap2.get('CommunicationNumberQualifier_07'));
                            objBillingProvider.put('BillingProviderContactInformation.ResponseContactCommunicationNumber_08', (String)loopMap2.get('ResponseContactCommunicationNumber_08'));
                            objBillingProvider.put('BillingProviderContactInformation.ContactInquiryReference_09', (String)loopMap2.get('ContactInquiryReference_09'));
                        }
                    }

                    // Groups.Transactions.Loop2000A.Loop2000B
                    List<Object> Loop2000B = (List<Object>)loopMap.get('Loop2000B');
                    for (Object itemLoop2000B : Loop2000B) {
                        Map<String, Object> loopMap2 = (Map<String, Object>)itemLoop2000B;

                        // Groups.Transactions.Loop2000A.Loop2000B.HL_SubscriberHierarchicalLevel
                        Map<String, Object> HL_SubscriberHierarchicalLevel = (Map<String, Object>)loopMap2.get('HL_SubscriberHierarchicalLevel');
                        objSubscriberInformation.put('SubscriberHierarchicalLevel.HierarchicalIDNumber_01', (String)HL_SubscriberHierarchicalLevel.get('HierarchicalIDNumber_01'));
                        objSubscriberInformation.put('SubscriberHierarchicalLevel.HierarchicalParentIDNumber_02', (String)HL_SubscriberHierarchicalLevel.get('HierarchicalParentIDNumber_02'));
                        objSubscriberInformation.put('SubscriberHierarchicalLevel.HierarchicalLevelCode_03', (String)HL_SubscriberHierarchicalLevel.get('HierarchicalLevelCode_03'));
                        objSubscriberInformation.put('SubscriberHierarchicalLevel.HierarchicalChildCode_04', (String)HL_SubscriberHierarchicalLevel.get('HierarchicalChildCode_04'));

                        // Groups.Transactions.Loop2000A.Loop2000B.SBR_SubscriberInformation
                        Map<String, Object> SBR_SubscriberInformation = (Map<String, Object>)loopMap2.get('SBR_SubscriberInformation');
                        objSubscriberInformation.put('SubscriberInformation.PayerResponsibilitySequenceNumberCode_01', (String)SBR_SubscriberInformation.get('PayerResponsibilitySequenceNumberCode_01'));
                        objSubscriberInformation.put('SubscriberInformation.IndividualRelationshipCode_02', (String)SBR_SubscriberInformation.get('IndividualRelationshipCode_02'));
                        objSubscriberInformation.put('SubscriberInformation.OtherInsuredGroupName_04', (String)SBR_SubscriberInformation.get('OtherInsuredGroupName_04'));
                        objSubscriberInformation.put('SubscriberInformation.InsuranceTypeCode_05', (String)SBR_SubscriberInformation.get('InsuranceTypeCode_05'));
                        objSubscriberInformation.put('SubscriberInformation.CoordinationofBenefitsCode_06', (String)SBR_SubscriberInformation.get('CoordinationofBenefitsCode_06'));
                        objSubscriberInformation.put('SubscriberInformation.YesNoConditionorResponseCode_07', (String)SBR_SubscriberInformation.get('YesNoConditionorResponseCode_07'));
                        objSubscriberInformation.put('SubscriberInformation.EmploymentStatusCode_08', (String)SBR_SubscriberInformation.get('EmploymentStatusCode_08'));
                        objSubscriberInformation.put('SubscriberInformation.ClaimFilingIndicatorCode_09', (String)SBR_SubscriberInformation.get('ClaimFilingIndicatorCode_09'));

                        // Groups.Transactions.Loop2000A.Loop2000B.AllNM1_3
                        Map<String, Object> AllNM1_3 = (Map<String, Object>)loopMap2.get('AllNM1');
                        
                        // Groups.Transactions.Loop2000A.Loop2000B.AllNM1_3.Loop2010BA
                        Map<String, Object> Loop2010BA = (Map<String, Object>)AllNM1_3.get('Loop2010BA');
                        Map<String, Object> NM1_SubscriberName = (Map<String, Object>)Loop2010BA.get('NM1_SubscriberName');
                        System.debug(NM1_SubscriberName);
                        if (NM1_SubscriberName != null) {
                            objSubscriberInformation.put('SubscriberName.EntityIdentifierCode_01', (String)NM1_SubscriberName.get('EntityIdentifierCode_01'));
                            objSubscriberInformation.put('SubscriberName.EntityTypeQualifier_02', (String)NM1_SubscriberName.get('EntityTypeQualifier_02'));
                            objSubscriberInformation.put('SubscriberName.ResponseContactLastorOrganizationName_03', (String)NM1_SubscriberName.get('ResponseContactLastorOrganizationName_03'));
                            objSubscriberInformation.put('SubscriberName.ResponseContactFirstName_04', (String)NM1_SubscriberName.get('ResponseContactFirstName_04'));
                            objSubscriberInformation.put('SubscriberName.ResponseContactMiddleName_05', (String)NM1_SubscriberName.get('ResponseContactMiddleName_05'));
                            objSubscriberInformation.put('SubscriberName.NamePrefix_06', (String)NM1_SubscriberName.get('NamePrefix_06'));
                            objSubscriberInformation.put('SubscriberName.ResponseContactNameSuffix_07', (String)NM1_SubscriberName.get('ResponseContactNameSuffix_07'));
                            objSubscriberInformation.put('SubscriberName.IdentificationCodeQualifier_08', (String)NM1_SubscriberName.get('IdentificationCodeQualifier_08'));
                            objSubscriberInformation.put('SubscriberName.EntityRelationshipCode_10', (String)NM1_SubscriberName.get('EntityRelationshipCode_10'));
                            objSubscriberInformation.put('SubscriberName.EntityIdentifierCode_11', (String)NM1_SubscriberName.get('EntityIdentifierCode_11'));
                            objSubscriberInformation.put('SubscriberName.NameLastorOrganizationName_12', (String)NM1_SubscriberName.get('NameLastorOrganizationName_12'));
                            objSubscriberInformation.put('SubscriberName.ResponseContactIdentifier_09', (String)NM1_SubscriberName.get('ResponseContactIdentifier_09'));
                            outputMap.put('insurancePolicy', (String)NM1_SubscriberName.get('ResponseContactIdentifier_09'));
                        }
                        Map<String, Object> N3_SubscriberAddress = (Map<String, Object>)Loop2010BA.get('N3_SubscriberAddress');
                        if (N3_SubscriberAddress != null) {
                            objSubscriberInformation.put('SubscriberAddress.ResponseContactAddressLine_01', (String)N3_SubscriberAddress.get('ResponseContactAddressLine_01'));
                            objSubscriberInformation.put('SubscriberAddress.ResponseContactAddressLine_02', (String)N3_SubscriberAddress.get('ResponseContactAddressLine_02'));
                        }
                        Map<String, Object> N4_SubscriberCity_State_ZIPCode = (Map<String, Object>)Loop2010BA.get('N4_SubscriberCity_State_ZIPCode');
                        if (N4_SubscriberCity_State_ZIPCode != null) {
                            objSubscriberInformation.put('SubscriberCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01', (String)N4_SubscriberCity_State_ZIPCode.get('AdditionalPatientInformationContactCityName_01'));
                            objSubscriberInformation.put('SubscriberCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02', (String)N4_SubscriberCity_State_ZIPCode.get('AdditionalPatientInformationContactStateCode_02'));
                            objSubscriberInformation.put('SubscriberCity_State_ZIPCode.AdditionalPatientInformationContactPostalZoneorZIPCode_03', (String)N4_SubscriberCity_State_ZIPCode.get('AdditionalPatientInformationContactPostalZoneorZIPCode_03'));
                            objSubscriberInformation.put('SubscriberCity_State_ZIPCode.CountryCode_04', (String)N4_SubscriberCity_State_ZIPCode.get('CountryCode_04'));
                            objSubscriberInformation.put('SubscriberCity_State_ZIPCode.LocationQualifier_05', (String)N4_SubscriberCity_State_ZIPCode.get('LocationQualifier_05'));
                            objSubscriberInformation.put('SubscriberCity_State_ZIPCode.LocationIdentifier_06', (String)N4_SubscriberCity_State_ZIPCode.get('LocationIdentifier_06'));
                            objSubscriberInformation.put('SubscriberCity_State_ZIPCode.CountrySubdivisionCode_07', (String)N4_SubscriberCity_State_ZIPCode.get('CountrySubdivisionCode_07'));
                        }
                        Map<String, Object> DMG_SubscriberDemographicInformation = (Map<String, Object>)Loop2010BA.get('DMG_SubscriberDemographicInformation');
                        if (DMG_SubscriberDemographicInformation != null) {
                            objSubscriberInformation.put('SubscriberDemographicInformation.DateTimePeriodFormatQualifier_01', (String)DMG_SubscriberDemographicInformation.get('DateTimePeriodFormatQualifier_01'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.DependentBirthDate_02', (String)DMG_SubscriberDemographicInformation.get('DependentBirthDate_02'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.DependentGenderCode_03', (String)DMG_SubscriberDemographicInformation.get('DependentGenderCode_03'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.MaritalStatusCode_04', (String)DMG_SubscriberDemographicInformation.get('MaritalStatusCode_04'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.CompositeRaceOrEthnicityInformation_05', (String)DMG_SubscriberDemographicInformation.get('CompositeRaceOrEthnicityInformation_05'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.CitizenshipStatusCode_06', (String)DMG_SubscriberDemographicInformation.get('CitizenshipStatusCode_06'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.CountryCode_07', (String)DMG_SubscriberDemographicInformation.get('CountryCode_07'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.BasisofVerificationCode_08', (String)DMG_SubscriberDemographicInformation.get('BasisofVerificationCode_08'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.Quantity_09', (String)DMG_SubscriberDemographicInformation.get('Quantity_09'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.CodeListQualifierCode_10', (String)DMG_SubscriberDemographicInformation.get('CodeListQualifierCode_10'));
                            objSubscriberInformation.put('SubscriberDemographicInformation.IndustryCode_11', (String)DMG_SubscriberDemographicInformation.get('IndustryCode_11'));
                        }

                        // Groups.Transactions.Loop2000A.Loop2000B.Loop2300
                        outputMap = populateLoop2300(loopMap2, outputMap, clmRecordType);

                        // Groups.Transactions.Loop2000A.Loop2000B.Loop2000C
                        List<Object> Loop2000C = (List<Object>)loopMap2.get('Loop2000C');
                        if (Loop2000C != null) {
                            for (Object itemLoop2000C : Loop2000C) {
                                Map<String, Object> loopMap3 = (Map<String, Object>)itemLoop2000C;
                                
                                Map<String, Object> HL_PatientHierarchicalLevel = (Map<String, Object>)loopMap3.get('HL_PatientHierarchicalLevel');
                                objPatientInformation.put('HL_PatientHierarchicalLevel.HierarchicalIDNumber_01', (String)HL_PatientHierarchicalLevel.get('HierarchicalIDNumber_01'));
                                objPatientInformation.put('HL_PatientHierarchicalLevel.HierarchicalParentIDNumber_02', (String)HL_PatientHierarchicalLevel.get('HierarchicalParentIDNumber_02'));
                                objPatientInformation.put('HL_PatientHierarchicalLevel.HierarchicalLevelCode_03', (String)HL_PatientHierarchicalLevel.get('HierarchicalLevelCode_03'));
                                objPatientInformation.put('HL_PatientHierarchicalLevel.HierarchicalChildCode_04', (String)HL_PatientHierarchicalLevel.get('HierarchicalChildCode_04'));

                                Map<String, Object> PAT_PatientInformation = (Map<String, Object>)loopMap3.get('PAT_PatientInformation');
                                objPatientInformation.put('PAT_PatientInformation.IndividualRelationshipCode_01', (String)PAT_PatientInformation.get('IndividualRelationshipCode_01'));
                                objPatientInformation.put('PAT_PatientInformation.PatientLocationCode_02', (String)PAT_PatientInformation.get('PatientLocationCode_02'));
                                objPatientInformation.put('PAT_PatientInformation.EmploymentStatusCode_03', (String)PAT_PatientInformation.get('EmploymentStatusCode_03'));
                                objPatientInformation.put('PAT_PatientInformation.StudentStatusCode_04', (String)PAT_PatientInformation.get('StudentStatusCode_04'));
                                objPatientInformation.put('PAT_PatientInformation.DateTimePeriodFormatQualifier_05', (String)PAT_PatientInformation.get('DateTimePeriodFormatQualifier_05'));
                                objPatientInformation.put('PAT_PatientInformation.PatientDeathDate_06', (String)PAT_PatientInformation.get('PatientDeathDate_06'));
                                objPatientInformation.put('PAT_PatientInformation.UnitorBasisforMeasurementCode_07', (String)PAT_PatientInformation.get('UnitorBasisforMeasurementCode_07'));
                                objPatientInformation.put('PAT_PatientInformation.PatientWeight_08', (String)PAT_PatientInformation.get('PatientWeight_08'));
                                objPatientInformation.put('PAT_PatientInformation.PregnancyIndicator_09', (String)PAT_PatientInformation.get('PregnancyIndicator_09'));

                                // Groups.Transactions.Loop2000A.Loop2000B.Loop2000C.Loop2010CA
                                Map<String, Object> Loop2010CA = (Map<String, Object>)loopMap3.get('Loop2010CA');
                                Map<String, Object> NM1_PatientName = (Map<String, Object>)Loop2010CA.get('NM1_PatientName');
                                objPatientInformation.put('NM1_PatientName.EntityIdentifierCode_01', (String)NM1_PatientName.get('EntityIdentifierCode_01'));
                                objPatientInformation.put('NM1_PatientName.EntityTypeQualifier_02', (String)NM1_PatientName.get('EntityTypeQualifier_02'));
                                objPatientInformation.put('NM1_PatientName.ResponseContactLastorOrganizationName_03', (String)NM1_PatientName.get('ResponseContactLastorOrganizationName_03'));
                                objPatientInformation.put('NM1_PatientName.ResponseContactFirstName_04', (String)NM1_PatientName.get('ResponseContactFirstName_04'));
                                objPatientInformation.put('NM1_PatientName.ResponseContactMiddleName_05', (String)NM1_PatientName.get('ResponseContactMiddleName_05'));
                                objPatientInformation.put('NM1_PatientName.NamePrefix_06', (String)NM1_PatientName.get('NamePrefix_06'));
                                objPatientInformation.put('NM1_PatientName.ResponseContactNameSuffix_07', (String)NM1_PatientName.get('ResponseContactNameSuffix_07'));
                                objPatientInformation.put('NM1_PatientName.IdentificationCodeQualifier_08', (String)NM1_PatientName.get('IdentificationCodeQualifier_08'));
                                objPatientInformation.put('NM1_PatientName.ResponseContactIdentifier_09', (String)NM1_PatientName.get('ResponseContactIdentifier_09'));
                                objPatientInformation.put('NM1_PatientName.EntityRelationshipCode_10', (String)NM1_PatientName.get('EntityRelationshipCode_10'));
                                objPatientInformation.put('NM1_PatientName.EntityIdentifierCode_11', (String)NM1_PatientName.get('EntityIdentifierCode_11'));
                                objPatientInformation.put('NM1_PatientName.NameLastorOrganizationName_12', (String)NM1_PatientName.get('NameLastorOrganizationName_12'));

                                Map<String, Object> N3_PatientAddress = (Map<String, Object>)Loop2010CA.get('N3_PatientAddress');
                                objPatientInformation.put('N3_PatientAddress.ResponseContactAddressLine_01', (String)N3_PatientAddress.get('ResponseContactAddressLine_01'));
                                objPatientInformation.put('N3_PatientAddress.ResponseContactAddressLine_02', (String)N3_PatientAddress.get('ResponseContactAddressLine_02'));

                                Map<String, Object> N4_PatientCity_State_ZIPCode = (Map<String, Object>)Loop2010CA.get('N4_PatientCity_State_ZIPCode');
                                objPatientInformation.put('N4_PatientCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01', (String)N4_PatientCity_State_ZIPCode.get('AdditionalPatientInformationContactCityName_01'));
                                objPatientInformation.put('N4_PatientCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02', (String)N4_PatientCity_State_ZIPCode.get('AdditionalPatientInformationContactStateCode_02'));
                                objPatientInformation.put('N4_PatientCity_State_ZIPCode.AdditionalPatientInformationContactPostalZoneorZIPCode_03', (String)N4_PatientCity_State_ZIPCode.get('AdditionalPatientInformationContactPostalZoneorZIPCode_03'));
                                objPatientInformation.put('N4_PatientCity_State_ZIPCode.CountryCode_04', (String)N4_PatientCity_State_ZIPCode.get('CountryCode_04'));
                                objPatientInformation.put('N4_PatientCity_State_ZIPCode.LocationQualifier_05', (String)N4_PatientCity_State_ZIPCode.get('LocationQualifier_05'));
                                objPatientInformation.put('N4_PatientCity_State_ZIPCode.LocationIdentifier_06', (String)N4_PatientCity_State_ZIPCode.get('LocationIdentifier_06'));
                                objPatientInformation.put('N4_PatientCity_State_ZIPCode.CountrySubdivisionCode_07', (String)N4_PatientCity_State_ZIPCode.get('CountrySubdivisionCode_07'));

                                Map<String, Object> DMG_PatientDemographicInformation = (Map<String, Object>)Loop2010CA.get('DMG_PatientDemographicInformation');
                                objPatientInformation.put('DMG_PatientDemographicInformation.DateTimePeriodFormatQualifier_01', (String)DMG_PatientDemographicInformation.get('DateTimePeriodFormatQualifier_01'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.DependentBirthDate_02', (String)DMG_PatientDemographicInformation.get('DependentBirthDate_02'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.DependentGenderCode_03', (String)DMG_PatientDemographicInformation.get('DependentGenderCode_03'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.MaritalStatusCode_04', (String)DMG_PatientDemographicInformation.get('MaritalStatusCode_04'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.CompositeRaceOrEthnicityInformation_05', (String)DMG_PatientDemographicInformation.get('CompositeRaceOrEthnicityInformation_05'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.CitizenshipStatusCode_06', (String)DMG_PatientDemographicInformation.get('CitizenshipStatusCode_06'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.CountryCode_07', (String)DMG_PatientDemographicInformation.get('CountryCode_07'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.BasisofVerificationCode_08', (String)DMG_PatientDemographicInformation.get('BasisofVerificationCode_08'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.Quantity_09', (String)DMG_PatientDemographicInformation.get('Quantity_09'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.CodeListQualifierCode_10', (String)DMG_PatientDemographicInformation.get('CodeListQualifierCode_10'));
                                objPatientInformation.put('DMG_PatientDemographicInformation.IndustryCode_11', (String)DMG_PatientDemographicInformation.get('IndustryCode_11'));

                                // Groups.Transactions.Loop2000A.Loop2000B.Loop2000C.Loop2300
                                outputMap = populateLoop2300(loopMap3, outputMap, clmRecordType);
                            }
                        }
                    }
                }

                outputMap.put('submitter', objSubmitter);
                outputMap.put('billingProvider', objBillingProvider);
                outputMap.put('subscriberInformation', objSubscriberInformation);
                outputMap.put('patientInformation', objPatientInformation);

                output.add(outputMap);
            }

        }

        return output;
    }

    public static Map<String, Object> populateLoop2300(Map<String, Object> input, Map<String, Object> output, String clmRecordType){
        Map<String, Object> objClaimInformation = new Map<String, Object>();
        Map<String, Object> objServiceFacility = new Map<String, Object>();
        Map<String, Object> objReferringProvider = new Map<String, Object>();
        Map<String, Object> objRenderingProvider = new Map<String, Object>();
        Map<String, Object> objAttendingProvider = new Map<String, Object>();
        List<Object> claimLineItemsList = new List<Object>();
        
        // Groups.Transactions.Loop2000A.Loop2000B.Loop2300
        List<Object> Loop2300 = (List<Object>)input.get('Loop2300');
        if (Loop2300 != null) {
            for (Object itemLoop2300 : Loop2300) {
                Map<String, Object> loopMap3 = (Map<String, Object>)itemLoop2300;

                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.CLM_ClaimInformation
                Map<String, Object> CLM_ClaimInformation = (Map<String, Object>)loopMap3.get('CLM_ClaimInformation');
                objClaimInformation.put('ClaimInformation.PatientControlNumber_01', (String)CLM_ClaimInformation.get('PatientControlNumber_01'));
                objClaimInformation.put('ClaimInformation.TotalClaimChargeAmount_02', (String)CLM_ClaimInformation.get('TotalClaimChargeAmount_02'));
                objClaimInformation.put('ClaimInformation.ClaimFilingIndicatorCode_03', (String)CLM_ClaimInformation.get('ClaimFilingIndicatorCode_03'));
                objClaimInformation.put('ClaimInformation.NonInstitutionalClaimTypeCode_04', (String)CLM_ClaimInformation.get('NonInstitutionalClaimTypeCode_04'));
                objClaimInformation.put('ClaimInformation.ProviderorSupplierSignatureIndicator_06', (String)CLM_ClaimInformation.get('ProviderorSupplierSignatureIndicator_06'));
                objClaimInformation.put('ClaimInformation.AssignmentorPlanParticipationCode_07', (String)CLM_ClaimInformation.get('AssignmentorPlanParticipationCode_07'));
                objClaimInformation.put('ClaimInformation.BenefitsAssignmentCertificationIndicator_08', (String)CLM_ClaimInformation.get('BenefitsAssignmentCertificationIndicator_08'));
                objClaimInformation.put('ClaimInformation.ReleaseofInformationCode_09', (String)CLM_ClaimInformation.get('ReleaseofInformationCode_09'));
                objClaimInformation.put('ClaimInformation.PatientSignatureSourceCode_10', (String)CLM_ClaimInformation.get('PatientSignatureSourceCode_10'));
                // objClaimInformation.put('ClaimInformation.RelatedCausesInformation_11', (String)CLM_ClaimInformation.get('RelatedCausesInformation_11'));
                objClaimInformation.put('ClaimInformation.SpecialProgramIndicator_12', (String)CLM_ClaimInformation.get('SpecialProgramIndicator_12'));
                objClaimInformation.put('ClaimInformation.YesNoConditionorResponseCode_13', (String)CLM_ClaimInformation.get('YesNoConditionorResponseCode_13'));
                objClaimInformation.put('ClaimInformation.LevelofServiceCode_14', (String)CLM_ClaimInformation.get('LevelofServiceCode_14'));
                objClaimInformation.put('ClaimInformation.YesNoConditionorResponseCode_15', (String)CLM_ClaimInformation.get('YesNoConditionorResponseCode_15'));
                objClaimInformation.put('ClaimInformation.ProviderAgreementCode_16', (String)CLM_ClaimInformation.get('ProviderAgreementCode_16'));
                objClaimInformation.put('ClaimInformation.ClaimStatusCode_17', (String)CLM_ClaimInformation.get('ClaimStatusCode_17'));
                objClaimInformation.put('ClaimInformation.YesNoConditionorResponseCode_18', (String)CLM_ClaimInformation.get('YesNoConditionorResponseCode_18'));
                objClaimInformation.put('ClaimInformation.PredeterminationofBenefitsCode_19', (String)CLM_ClaimInformation.get('PredeterminationofBenefitsCode_19'));
                objClaimInformation.put('ClaimInformation.DelayReasonCode_20', (String)CLM_ClaimInformation.get('DelayReasonCode_20'));
                Map<String, Object> HealthCareServiceLocationInformation_05 = (Map<String, Object>)CLM_ClaimInformation.get('HealthCareServiceLocationInformation_05');
                objClaimInformation.put('HealthCareServiceLocationInformation.FacilityTypeCode_01', (String)HealthCareServiceLocationInformation_05.get('FacilityTypeCode_01'));
                objClaimInformation.put('HealthCareServiceLocationInformation.FacilityCodeQualifier_02', (String)HealthCareServiceLocationInformation_05.get('FacilityCodeQualifier_02'));
                objClaimInformation.put('HealthCareServiceLocationInformation.ClaimFrequencyTypeCode_03', (String)HealthCareServiceLocationInformation_05.get('ClaimFrequencyTypeCode_03'));

                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.AllDTP
                Map<String, Object> AllDTP = (Map<String, Object>)loopMap3.get('AllDTP');
                if(AllDTP != null) {
                    Map<String, Object> DTP_StatementDates = (Map<String, Object>)AllDTP.get('DTP_StatementDates');
                    if (DTP_StatementDates != null) {
                        objClaimInformation.put('StatementDates.DateTimeQualifier_01', DTP_StatementDates.get('DateTimeQualifier_01'));
                        objClaimInformation.put('StatementDates.DateTimePeriodFormatQualifier_02', DTP_StatementDates.get('DateTimePeriodFormatQualifier_02'));
                        objClaimInformation.put('StatementDates.DateTimePeriod_03', DTP_StatementDates.get('DateTimePeriod_03'));
                    }
                    Map<String, Object> DTP_Date_RepricerReceivedDate = (Map<String, Object>)AllDTP.get('DTP_Date_RepricerReceivedDate');
                    if (DTP_Date_RepricerReceivedDate != null) {
                        objClaimInformation.put('Date_RepricerReceivedDate.DateTimeQualifier_01', (String)DTP_Date_RepricerReceivedDate.get('DateTimeQualifier_01'));
                        objClaimInformation.put('Date_RepricerReceivedDate.DateTimePeriodFormatQualifier_02', (String)DTP_Date_RepricerReceivedDate.get('DateTimePeriodFormatQualifier_02'));
                        objClaimInformation.put('Date_RepricerReceivedDate.DateTimePeriod_03', (String)DTP_Date_RepricerReceivedDate.get('DateTimePeriod_03'));
                    }
                    Map<String, Object> DTP_Date_Admission = (Map<String, Object>)AllDTP.get('DTP_Date_Admission');
                    if (DTP_Date_Admission != null) {
                        objClaimInformation.put('AdmissionDate_Hour.DateTimeQualifier_01', (String)DTP_Date_Admission.get('DateTimeQualifier_01'));
                        objClaimInformation.put('AdmissionDate_Hour.DateTimePeriodFormatQualifier_02', (String)DTP_Date_Admission.get('DateTimePeriodFormatQualifier_02'));
                        objClaimInformation.put('AdmissionDate_Hour.DateTimePeriod_03', (String)DTP_Date_Admission.get('DateTimePeriod_03'));
                    }      
                    Map<String, Object> DTP_AdmissionDate_Hour = (Map<String, Object>)AllDTP.get('DTP_AdmissionDate_Hour');
                    if (DTP_AdmissionDate_Hour != null) {
                        objClaimInformation.put('AdmissionDate_Hour.DateTimeQualifier_01', (String)DTP_AdmissionDate_Hour.get('DateTimeQualifier_01'));
                        objClaimInformation.put('AdmissionDate_Hour.DateTimePeriodFormatQualifier_02', (String)DTP_AdmissionDate_Hour.get('DateTimePeriodFormatQualifier_02'));
                        objClaimInformation.put('AdmissionDate_Hour.DateTimePeriod_03', (String)DTP_AdmissionDate_Hour.get('DateTimePeriod_03'));
                    }   
                    Map<String, Object> DTP_DischargeHour = (Map<String, Object>)AllDTP.get('DTP_DischargeHour');
                    if (DTP_DischargeHour != null) {
                        objClaimInformation.put('DischargeHour.DateTimeQualifier_01', (String)DTP_DischargeHour.get('DateTimeQualifier_01'));
                        objClaimInformation.put('DischargeHour.DateTimePeriodFormatQualifier_02', (String)DTP_DischargeHour.get('DateTimePeriodFormatQualifier_02'));
                        objClaimInformation.put('DischargeHour.DateTimePeriod_03', (String)DTP_DischargeHour.get('DateTimePeriod_03'));
                    }
                }
                
                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.CL1_InstitutionalClaimCode
                Map<String, Object> CL1_InstitutionalClaimCode = (Map<String, Object>)loopMap3.get('CL1_InstitutionalClaimCode');
                if(CL1_InstitutionalClaimCode != null){
                    objClaimInformation.put('InstitutionalClaimCode.AdmissionTypeCode_01', (String)CL1_InstitutionalClaimCode.get('AdmissionTypeCode_01'));
                    objClaimInformation.put('InstitutionalClaimCode.AdmissionSourceCode_02', (String)CL1_InstitutionalClaimCode.get('AdmissionSourceCode_02'));
                    objClaimInformation.put('InstitutionalClaimCode.PatientStatusCode_03', (String)CL1_InstitutionalClaimCode.get('PatientStatusCode_03'));
                    objClaimInformation.put('InstitutionalClaimCode.NursingHomeResidentialStatusCode_04', (String)CL1_InstitutionalClaimCode.get('NursingHomeResidentialStatusCode_04'));
                }    
                
                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.AllREF
                Map<String, Object> AllREF = (Map<String, Object>)loopMap3.get('AllREF');
                if (allREF != null) {
                    Map<String, Object> REF_PriorAuthorization = (Map<String, Object>)AllREF.get('REF_PriorAuthorization');
                    if (REF_PriorAuthorization != null) {
                        objClaimInformation.put('PriorAuthorization.ReferenceIdentificationQualifier_01', (String)REF_PriorAuthorization.get('ReferenceIdentificationQualifier_01'));
                        objClaimInformation.put('PriorAuthorization.MemberGrouporPolicyNumber_02', (String)REF_PriorAuthorization.get('MemberGrouporPolicyNumber_02'));
                    }
                    Map<String, Object> REF_RepricedClaimNumber = (Map<String, Object>)AllREF.get('REF_RepricedClaimNumber');
                    if (REF_RepricedClaimNumber != null) {
                        objClaimInformation.put('ReferenceIdentificationQualifier_01', (String)REF_RepricedClaimNumber.get('ReferenceIdentificationQualifier_01'));
                        objClaimInformation.put('MemberGrouporPolicyNumber_02', (String)REF_RepricedClaimNumber.get('MemberGrouporPolicyNumber_02'));                                       
                    }
                    Map<String, Object> REF_MedicalRecordNumber = (Map<String, Object>)AllREF.get('REF_MedicalRecordNumber');
                    if (REF_MedicalRecordNumber != null) {
                        objClaimInformation.put('ReferenceIdentificationQualifier_01', (String)REF_MedicalRecordNumber.get('ReferenceIdentificationQualifier_01'));
                        objClaimInformation.put('MemberGrouporPolicyNumber_02', (String)REF_MedicalRecordNumber.get('MemberGrouporPolicyNumber_02'));                                         
                    }
                }
                
                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.AllNTE
                Map<String, Object> AllNTE = (Map<String, Object>)loopMap3.get('AllNTE');
                if (AllNTE != null) {
                    Map<String, Object> NTE_BillingNote = (Map<String, Object>)AllNTE.get('NTE_BillingNote');
                    if (NTE_BillingNote != null) {
                        objClaimInformation.put('BillingNote.BillingNoteText_02', (String)NTE_BillingNote.get('BillingNoteText_02'));
                        objClaimInformation.put('BillingNote.NoteReferenceCode_01', (String)NTE_BillingNote.get('NoteReferenceCode_01'));
                    }
                }

                Map<String, Object> NTE_ClaimNote = (Map<String, Object>)loopMap3.get('NTE_ClaimNote');
                if (NTE_ClaimNote != null) {
                    objClaimInformation.put('ClaimNote.BillingNoteText_02', (String)NTE_ClaimNote.get('BillingNoteText_02'));
                    objClaimInformation.put('ClaimNote.NoteReferenceCode_01', (String)NTE_ClaimNote.get('NoteReferenceCode_01'));
                }

                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.AllHI
                Map<String, Object> AllHI = (Map<String, Object>)loopMap3.get('AllHI');
                if (AllHI != null) {
                    Map<String, Object> HI_HealthCareDiagnosisCode = (Map<String, Object>)AllHI.get('HI_HealthCareDiagnosisCode');
                    if(HI_HealthCareDiagnosisCode != null){
                        Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_01');
                        if(HealthCareCodeInformation_01 != null){
                            objClaimInformation.put('HealthCareCodeInformation_01.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_01.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_01.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_01.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_01.DateTimePeriod_04', (String)HealthCareCodeInformation_01.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_01.MonetaryAmount_05', (String)HealthCareCodeInformation_01.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_01.Quantity_06', (String)HealthCareCodeInformation_01.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_01.VersionIdentifier_07', (String)HealthCareCodeInformation_01.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_01.IndustryCode_08', (String)HealthCareCodeInformation_01.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_01.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_02 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_02');
                        if(HealthCareCodeInformation_02 != null){
                            objClaimInformation.put('HealthCareCodeInformation_02.CodeListQualifierCode_01', (String)HealthCareCodeInformation_02.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_02.IndustryCode_02', (String)HealthCareCodeInformation_02.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_02.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_02.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_02.DateTimePeriod_04', (String)HealthCareCodeInformation_02.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_02.MonetaryAmount_05', (String)HealthCareCodeInformation_02.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_02.Quantity_06', (String)HealthCareCodeInformation_02.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_02.VersionIdentifier_07', (String)HealthCareCodeInformation_02.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_02.IndustryCode_08', (String)HealthCareCodeInformation_02.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_02.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_02.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_03 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_03');
                        if(HealthCareCodeInformation_03 != null){
                            objClaimInformation.put('HealthCareCodeInformation_03.CodeListQualifierCode_01', (String)HealthCareCodeInformation_03.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_03.IndustryCode_02', (String)HealthCareCodeInformation_03.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_03.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_03.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_03.DateTimePeriod_04', (String)HealthCareCodeInformation_03.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_03.MonetaryAmount_05', (String)HealthCareCodeInformation_03.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_03.Quantity_06', (String)HealthCareCodeInformation_03.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_03.VersionIdentifier_07', (String)HealthCareCodeInformation_03.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_03.IndustryCode_08', (String)HealthCareCodeInformation_03.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_03.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_03.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_04 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_04');
                        if(HealthCareCodeInformation_04 != null){
                            objClaimInformation.put('HealthCareCodeInformation_04.CodeListQualifierCode_01', (String)HealthCareCodeInformation_04.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_04.IndustryCode_02', (String)HealthCareCodeInformation_04.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_04.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_04.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_04.DateTimePeriod_04', (String)HealthCareCodeInformation_04.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_04.MonetaryAmount_05', (String)HealthCareCodeInformation_04.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_04.Quantity_06', (String)HealthCareCodeInformation_04.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_04.VersionIdentifier_07', (String)HealthCareCodeInformation_04.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_04.IndustryCode_08', (String)HealthCareCodeInformation_04.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_04.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_04.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_05 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_05');
                        if(HealthCareCodeInformation_05 != null){
                            objClaimInformation.put('HealthCareCodeInformation_05.CodeListQualifierCode_01', (String)HealthCareCodeInformation_05.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_05.IndustryCode_02', (String)HealthCareCodeInformation_05.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_05.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_05.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_05.DateTimePeriod_04', (String)HealthCareCodeInformation_05.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_05.MonetaryAmount_05', (String)HealthCareCodeInformation_05.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_05.Quantity_06', (String)HealthCareCodeInformation_05.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_05.VersionIdentifier_07', (String)HealthCareCodeInformation_05.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_05.IndustryCode_08', (String)HealthCareCodeInformation_05.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_05.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_05.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_06 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_06');
                        if(HealthCareCodeInformation_06 != null){
                            objClaimInformation.put('HealthCareCodeInformation_06.CodeListQualifierCode_01', (String)HealthCareCodeInformation_06.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_06.IndustryCode_02', (String)HealthCareCodeInformation_06.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_06.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_06.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_06.DateTimePeriod_04', (String)HealthCareCodeInformation_06.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_06.MonetaryAmount_05', (String)HealthCareCodeInformation_06.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_06.Quantity_06', (String)HealthCareCodeInformation_06.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_06.VersionIdentifier_07', (String)HealthCareCodeInformation_06.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_06.IndustryCode_08', (String)HealthCareCodeInformation_06.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_06.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_06.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_07 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_07');
                        if(HealthCareCodeInformation_07 != null){
                            objClaimInformation.put('HealthCareCodeInformation_07.CodeListQualifierCode_01', (String)HealthCareCodeInformation_07.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_07.IndustryCode_02', (String)HealthCareCodeInformation_07.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_07.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_07.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_07.DateTimePeriod_04', (String)HealthCareCodeInformation_07.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_07.MonetaryAmount_05', (String)HealthCareCodeInformation_07.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_07.Quantity_06', (String)HealthCareCodeInformation_07.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_07.VersionIdentifier_07', (String)HealthCareCodeInformation_07.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_07.IndustryCode_08', (String)HealthCareCodeInformation_07.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_07.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_07.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_08 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_08');
                        if(HealthCareCodeInformation_08 != null){
                            objClaimInformation.put('HealthCareCodeInformation_08.CodeListQualifierCode_01', (String)HealthCareCodeInformation_08.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_08.IndustryCode_02', (String)HealthCareCodeInformation_08.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_08.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_08.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_08.DateTimePeriod_04', (String)HealthCareCodeInformation_08.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_08.MonetaryAmount_05', (String)HealthCareCodeInformation_08.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_08.Quantity_06', (String)HealthCareCodeInformation_08.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_08.VersionIdentifier_07', (String)HealthCareCodeInformation_08.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_08.IndustryCode_08', (String)HealthCareCodeInformation_08.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_08.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_08.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_09 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_09');
                        if(HealthCareCodeInformation_09 != null){
                            objClaimInformation.put('HealthCareCodeInformation_09.CodeListQualifierCode_01', (String)HealthCareCodeInformation_09.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_09.IndustryCode_02', (String)HealthCareCodeInformation_09.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_09.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_09.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_09.DateTimePeriod_04', (String)HealthCareCodeInformation_09.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_09.MonetaryAmount_05', (String)HealthCareCodeInformation_09.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_09.Quantity_06', (String)HealthCareCodeInformation_09.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_09.VersionIdentifier_07', (String)HealthCareCodeInformation_09.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_09.IndustryCode_08', (String)HealthCareCodeInformation_09.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_09.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_09.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_10 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_10');
                        if(HealthCareCodeInformation_10 != null){
                            objClaimInformation.put('HealthCareCodeInformation_10.CodeListQualifierCode_01', (String)HealthCareCodeInformation_10.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_10.IndustryCode_02', (String)HealthCareCodeInformation_10.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_10.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_10.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_10.DateTimePeriod_04', (String)HealthCareCodeInformation_10.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_10.MonetaryAmount_05', (String)HealthCareCodeInformation_10.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_10.Quantity_06', (String)HealthCareCodeInformation_10.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_10.VersionIdentifier_07', (String)HealthCareCodeInformation_10.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_10.IndustryCode_08', (String)HealthCareCodeInformation_10.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_10.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_10.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_11 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_11');
                        if(HealthCareCodeInformation_11 != null){
                            objClaimInformation.put('HealthCareCodeInformation_11.CodeListQualifierCode_01', (String)HealthCareCodeInformation_11.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_11.IndustryCode_02', (String)HealthCareCodeInformation_11.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_11.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_11.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_11.DateTimePeriod_04', (String)HealthCareCodeInformation_11.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_11.MonetaryAmount_05', (String)HealthCareCodeInformation_11.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_11.Quantity_06', (String)HealthCareCodeInformation_11.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_11.VersionIdentifier_07', (String)HealthCareCodeInformation_11.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_11.IndustryCode_08', (String)HealthCareCodeInformation_11.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_11.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_11.get('YesNoConditionorResponseCode_09'));
                        }
                        Map<String, Object> HealthCareCodeInformation_12 = (Map<String, Object>)HI_HealthCareDiagnosisCode.get('HealthCareCodeInformation_12');
                        if(HealthCareCodeInformation_12 != null){
                            objClaimInformation.put('HealthCareCodeInformation_12.CodeListQualifierCode_01', (String)HealthCareCodeInformation_12.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('HealthCareCodeInformation_12.IndustryCode_02', (String)HealthCareCodeInformation_12.get('IndustryCode_02'));
                            objClaimInformation.put('HealthCareCodeInformation_12.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_12.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('HealthCareCodeInformation_12.DateTimePeriod_04', (String)HealthCareCodeInformation_12.get('DateTimePeriod_04'));
                            objClaimInformation.put('HealthCareCodeInformation_12.MonetaryAmount_05', (String)HealthCareCodeInformation_12.get('MonetaryAmount_05'));
                            objClaimInformation.put('HealthCareCodeInformation_12.Quantity_06', (String)HealthCareCodeInformation_12.get('Quantity_06'));
                            objClaimInformation.put('HealthCareCodeInformation_12.VersionIdentifier_07', (String)HealthCareCodeInformation_12.get('VersionIdentifier_07'));
                            objClaimInformation.put('HealthCareCodeInformation_12.IndustryCode_08', (String)HealthCareCodeInformation_12.get('IndustryCode_08'));
                            objClaimInformation.put('HealthCareCodeInformation_12.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_12.get('YesNoConditionorResponseCode_09'));
                        }
                    }

                    Map<String, Object> HI_DiagnosisRelatedGroup_DRG_Information = (Map<String, Object>)AllHI.get('HI_DiagnosisRelatedGroup_DRG_Information');
                    if (HI_DiagnosisRelatedGroup_DRG_Information != null) {
                        Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)HI_DiagnosisRelatedGroup_DRG_Information.get('HealthCareCodeInformation_01');
                        if (HealthCareCodeInformation_01 != null) {
                            objClaimInformation.put('DiagnosisRelatedGroup_DRG_Information.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('DiagnosisRelatedGroup_DRG_Information.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                            objClaimInformation.put('DiagnosisRelatedGroup_DRG_Information.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_01.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('DiagnosisRelatedGroup_DRG_Information.DateTimePeriod_04', (String)HealthCareCodeInformation_01.get('DateTimePeriod_04'));
                            objClaimInformation.put('DiagnosisRelatedGroup_DRG_Information.MonetaryAmount_05', (String)HealthCareCodeInformation_01.get('MonetaryAmount_05'));
                            objClaimInformation.put('DiagnosisRelatedGroup_DRG_Information.Quantity_06', (String)HealthCareCodeInformation_01.get('Quantity_06'));
                            objClaimInformation.put('DiagnosisRelatedGroup_DRG_Information.VersionIdentifier_07', (String)HealthCareCodeInformation_01.get('VersionIdentifier_07'));
                            objClaimInformation.put('DiagnosisRelatedGroup_DRG_Information.IndustryCode_08', (String)HealthCareCodeInformation_01.get('IndustryCode_08'));
                            objClaimInformation.put('DiagnosisRelatedGroup_DRG_Information.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                        }
                    }

                    Map<String, Object> HI_PrincipalProcedureInformation = (Map<String, Object>)AllHI.get('HI_PrincipalProcedureInformation');
                    if (HI_PrincipalProcedureInformation != null) {
                        Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)HI_PrincipalProcedureInformation.get('HealthCareCodeInformation_01');
                        if (HealthCareCodeInformation_01 != null) {
                            objClaimInformation.put('PrincipalProcedureInformation_1.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('PrincipalProcedureInformation_1.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                            objClaimInformation.put('PrincipalProcedureInformation_1.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_01.get('DateTimePeriodFormatQualifier_03'));
                            objClaimInformation.put('PrincipalProcedureInformation_1.DateTimePeriod_04', (String)HealthCareCodeInformation_01.get('DateTimePeriod_04'));
                            objClaimInformation.put('PrincipalProcedureInformation_1.MonetaryAmount_05', (String)HealthCareCodeInformation_01.get('MonetaryAmount_05'));
                            objClaimInformation.put('PrincipalProcedureInformation_1.Quantity_06', (String)HealthCareCodeInformation_01.get('Quantity_06'));
                            objClaimInformation.put('PrincipalProcedureInformation_1.VersionIdentifier_07', (String)HealthCareCodeInformation_01.get('VersionIdentifier_07'));
                            objClaimInformation.put('PrincipalProcedureInformation_1.IndustryCode_08', (String)HealthCareCodeInformation_01.get('IndustryCode_08'));
                            objClaimInformation.put('PrincipalProcedureInformation_1.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                        }
                    }
                    // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.AllHI.HI_OtherProcedureInformation
                    List<Object> HI_OtherProcedureInformation = (List<Object>)AllHI.get('HI_OtherProcedureInformation');
                    if (HI_OtherProcedureInformation != null) {
                        for (Object itemOtherProcedureInformation : HI_OtherProcedureInformation) {
                            Map<String, Object> loopMap5 = (Map<String, Object>)itemOtherProcedureInformation;
                            
                            Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_01');
                            if (HealthCareCodeInformation_01 != null) {
                                List<Object> opiCodes = new List<Object>();
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_01.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_01.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_01.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_01.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_01.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_01.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);

                                objClaimInformation.put('otherProcedureCodes', opiCodes);
                            }
                            Map<String, Object> HealthCareCodeInformation_02 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_02');
                            if (HealthCareCodeInformation_02 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_02.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_02.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_02.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_02.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_02.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_02.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_02.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_02.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_02.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_03 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_03');
                            if (HealthCareCodeInformation_03 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_03.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_03.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_03.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_03.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_03.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_03.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_03.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_03.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_03.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_04 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_04');
                            if (HealthCareCodeInformation_04 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_04.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_04.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_04.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_04.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_04.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_04.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_04.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_04.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_04.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_05 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_05');
                            if (HealthCareCodeInformation_05 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_05.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_05.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_05.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_05.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_05.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_05.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_05.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_05.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_05.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_06 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_06');
                            if (HealthCareCodeInformation_06 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_06.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_06.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_06.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_06.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_06.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_06.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_06.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_06.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_06.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_07 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_07');
                            if (HealthCareCodeInformation_07 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_07.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_07.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_07.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_07.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_07.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_07.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_07.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_07.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_07.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_08 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_08');
                            if (HealthCareCodeInformation_08 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_08.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_08.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_08.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_08.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_08.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_08.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_08.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_08.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_08.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_09 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_09');
                            if (HealthCareCodeInformation_09 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_09.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_09.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_09.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_09.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_09.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_09.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_09.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_09.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_09.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_10 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_10');
                            if (HealthCareCodeInformation_10 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_10.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_10.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_10.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_10.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_10.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_10.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_10.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_10.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_10.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_11 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_11');
                            if (HealthCareCodeInformation_11 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_11.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_11.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_11.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_11.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_11.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_11.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_11.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_11.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_11.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_12 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_12');
                            if (HealthCareCodeInformation_12 != null) {
                                List<Object> opiCodes = (List<Object>)objClaimInformation.get('otherProcedureCodes');
                                Map<String, Object> opiCode = new Map<String, Object>();

                                opiCode.put('OtherProcedureInformation.CodeListQualifierCode_01', (String)HealthCareCodeInformation_12.get('CodeListQualifierCode_01'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_02', (String)HealthCareCodeInformation_12.get('IndustryCode_02'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_12.get('DateTimePeriodFormatQualifier_03'));
                                opiCode.put('OtherProcedureInformation.DateTimePeriod_04', (String)HealthCareCodeInformation_12.get('DateTimePeriod_04'));
                                opiCode.put('OtherProcedureInformation.MonetaryAmount_05', (String)HealthCareCodeInformation_12.get('MonetaryAmount_05'));
                                opiCode.put('OtherProcedureInformation.Quantity_06', (String)HealthCareCodeInformation_12.get('Quantity_06'));
                                opiCode.put('OtherProcedureInformation.VersionIdentifier_07', (String)HealthCareCodeInformation_12.get('VersionIdentifier_07'));
                                opiCode.put('OtherProcedureInformation.IndustryCode_08', (String)HealthCareCodeInformation_12.get('IndustryCode_08'));
                                opiCode.put('OtherProcedureInformation.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_12.get('YesNoConditionorResponseCode_09'));
                                opiCodes.add(opiCode);
                            }
                        }
                    }
                    // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.AllHI.HI_OccurrenceInformation
                    List<Object> HI_OccurrenceInformation = (List<Object>)AllHI.get('HI_OccurrenceInformation');
                    if (HI_OccurrenceInformation != null) {
                        for (Object itemOccurrenceInformation : HI_OccurrenceInformation) {
                            Map<String, Object> loopMap5 = (Map<String, Object>)itemOccurrenceInformation;

                            Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_01');
                            if (HealthCareCodeInformation_01 != null) {
                                List<Object> occurrenceCodes = new List<Object>();
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_01.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_01.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_01.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_01.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_01.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_01.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);

                                objClaimInformation.put('occurrenceCodes', occurrenceCodes);
                            }
                            Map<String, Object> HealthCareCodeInformation_02 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_02');
                            if (HealthCareCodeInformation_02 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_02.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_02.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_02.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_02.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_02.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_02.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_02.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_02.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_02.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_03 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_03');
                            if (HealthCareCodeInformation_03 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_03.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_03.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_03.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_03.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_03.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_03.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_03.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_03.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_03.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_04 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_04');
                            if (HealthCareCodeInformation_04 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_04.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_04.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_04.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_04.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_04.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_04.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_04.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_04.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_04.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_05 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_05');
                            if (HealthCareCodeInformation_05 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_05.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_05.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_05.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_05.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_05.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_05.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_05.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_05.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_05.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_06 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_06');
                            if (HealthCareCodeInformation_06 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_06.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_06.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_06.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_06.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_06.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_06.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_06.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_06.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_06.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_07 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_07');
                            if (HealthCareCodeInformation_07 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_07.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_07.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_07.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_07.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_07.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_07.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_07.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_07.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_07.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_08 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_08');
                            if (HealthCareCodeInformation_08 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_08.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_08.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_08.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_08.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_08.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_08.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_08.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_08.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_08.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_09 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_09');
                            if (HealthCareCodeInformation_09 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_09.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_09.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_09.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_09.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_09.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_09.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_09.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_09.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_09.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_10 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_10');
                            if (HealthCareCodeInformation_10 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_10.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_10.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_10.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_10.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_10.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_10.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_10.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_10.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_10.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_11 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_11');
                            if (HealthCareCodeInformation_11 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_11.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_11.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_11.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_11.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_11.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_11.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_11.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_11.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_11.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_12 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_12');
                            if (HealthCareCodeInformation_12 != null) {
                                List<Object> occurrenceCodes = (List<Object>)objClaimInformation.get('occurrenceCodes');
                                Map<String, Object> occCode = new Map<String, Object>();

                                occCode.put('OccurrenceInformationCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_12.get('CodeListQualifierCode_01'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_02', (String)HealthCareCodeInformation_12.get('IndustryCode_02'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_12.get('DateTimePeriodFormatQualifier_03'));
                                occCode.put('OccurrenceInformationCode.DateTimePeriod_04', (String)HealthCareCodeInformation_12.get('DateTimePeriod_04'));
                                occCode.put('OccurrenceInformationCode.MonetaryAmount_05', (String)HealthCareCodeInformation_12.get('MonetaryAmount_05'));
                                occCode.put('OccurrenceInformationCode.Quantity_06', (String)HealthCareCodeInformation_12.get('Quantity_06'));
                                occCode.put('OccurrenceInformationCode.VersionIdentifier_07', (String)HealthCareCodeInformation_12.get('VersionIdentifier_07'));
                                occCode.put('OccurrenceInformationCode.IndustryCode_08', (String)HealthCareCodeInformation_12.get('IndustryCode_08'));
                                occCode.put('OccurrenceInformationCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_12.get('YesNoConditionorResponseCode_09'));
                                occurrenceCodes.add(occCode);
                            }
                        }
                    }
                    // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.AllHI.HI_ValueInformation
                    List<Object> HI_ValueInformation = (List<Object>)AllHI.get('HI_ValueInformation');
                    if (HI_ValueInformation != null) {
                        for (Object itemHI_ValueInformation : HI_ValueInformation) {
                            Map<String, Object> loopMap5 = (Map<String, Object>)itemHI_ValueInformation;

                            Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_01');
                            if (HealthCareCodeInformation_01 != null) {
                                List<Object> valueCodes = new List<Object>();
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_01.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_01.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_01.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_01.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_01.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_01.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);

                                objClaimInformation.put('valueCodes', valueCodes);
                            }
                            Map<String, Object> HealthCareCodeInformation_02 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_02');
                            if (HealthCareCodeInformation_02 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_02.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_02.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_02.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_02.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_02.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_02.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_02.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_02.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_02.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_03 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_03');
                            if (HealthCareCodeInformation_03 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_03.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_03.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_03.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_03.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_03.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_03.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_03.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_03.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_03.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_04 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_04');
                            if (HealthCareCodeInformation_04 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_04.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_04.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_04.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_04.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_04.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_04.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_04.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_04.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_04.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_05 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_05');
                            if (HealthCareCodeInformation_05 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_05.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_05.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_05.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_05.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_05.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_05.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_05.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_05.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_05.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_06 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_06');
                            if (HealthCareCodeInformation_06 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_06.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_06.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_06.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_06.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_06.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_06.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_06.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_06.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_06.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_07 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_07');
                            if (HealthCareCodeInformation_07 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_07.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_07.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_07.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_07.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_07.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_07.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_07.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_07.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_07.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_08 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_08');
                            if (HealthCareCodeInformation_08 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_08.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_08.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_08.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_08.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_08.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_08.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_08.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_08.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_08.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_09 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_09');
                            if (HealthCareCodeInformation_09 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_09.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_09.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_09.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_09.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_09.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_09.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_09.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_09.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_09.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_10 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_10');
                            if (HealthCareCodeInformation_10 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_10.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_10.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_10.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_10.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_10.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_10.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_10.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_10.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_10.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_11 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_11');
                            if (HealthCareCodeInformation_11 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_11.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_11.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_11.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_11.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_11.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_11.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_11.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_11.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_11.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_12 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_12');
                            if (HealthCareCodeInformation_12 != null) {
                                List<Object> valueCodes = (List<Object>)objClaimInformation.get('valueCodes');
                                Map<String, Object> valueCode = new Map<String, Object>();

                                valueCode.put('ValueCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_12.get('CodeListQualifierCode_01'));
                                valueCode.put('ValueCode.IndustryCode_02', (String)HealthCareCodeInformation_12.get('IndustryCode_02'));
                                valueCode.put('ValueCode.DateTimePeriodFormatQualifier_03', (String)HealthCareCodeInformation_12.get('DateTimePeriodFormatQualifier_03'));
                                valueCode.put('ValueCode.DateTimePeriod_04', (String)HealthCareCodeInformation_12.get('DateTimePeriod_04'));
                                valueCode.put('ValueCode.MonetaryAmount_05', (String)HealthCareCodeInformation_12.get('MonetaryAmount_05'));
                                valueCode.put('ValueCode.Quantity_06', (String)HealthCareCodeInformation_12.get('Quantity_06'));
                                valueCode.put('ValueCode.VersionIdentifier_07', (String)HealthCareCodeInformation_12.get('VersionIdentifier_07'));
                                valueCode.put('ValueCode.IndustryCode_08', (String)HealthCareCodeInformation_12.get('IndustryCode_08'));
                                valueCode.put('ValueCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_12.get('YesNoConditionorResponseCode_09'));
                                valueCodes.add(valueCode);
                            }
                        }
                    }
                    Map<String, Object> HI_PrincipalDiagnosis = (Map<String, Object>)AllHI.get('HI_PrincipalDiagnosis');
                    if(HI_PrincipalDiagnosis != null){
                        Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)HI_PrincipalDiagnosis.get('HealthCareCodeInformation_01');
                        if(HealthCareCodeInformation_01 != null){
                            objClaimInformation.put('PrincipalDiagnosis.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('PrincipalDiagnosis.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                            objClaimInformation.put('PrincipalDiagnosis.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                        }
                    }
                    Map<String, Object> HI_Patient_ReasonForVisit = (Map<String, Object>)AllHI.get('HI_Patient_ReasonForVisit');
                    if(HI_Patient_ReasonForVisit != null){
                        Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)HI_Patient_ReasonForVisit.get('HealthCareCodeInformation_01');
                        if(HealthCareCodeInformation_01 != null){
                            objClaimInformation.put('PatientReason.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('PatientReason.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                            objClaimInformation.put('PatientReason.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                        }
                    }
                    Map<String, Object> HI_ExternalCauseofInjury = (Map<String, Object>)AllHI.get('HI_ExternalCauseofInjury');
                    if(HI_ExternalCauseofInjury != null){
                        List<Object> ExtCauseOfInjuryList = new List<Object>();
                        
                        Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_01');
                        if(HealthCareCodeInformation_01 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_02 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_02');
                        if(HealthCareCodeInformation_02 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_02.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_02.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_02.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_03 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_03');
                        if(HealthCareCodeInformation_03 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_03.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_03.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_03.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_04 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_04');
                        if(HealthCareCodeInformation_04 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_04.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_04.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_04.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_05 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_05');
                        if(HealthCareCodeInformation_05 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_05.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_05.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_05.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_06 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_06');
                        if(HealthCareCodeInformation_06 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_06.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_06.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_06.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_07 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_07');
                        if(HealthCareCodeInformation_07 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_07.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_07.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_07.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_08 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_08');
                        if(HealthCareCodeInformation_08 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_08.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_08.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_08.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_09 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_09');
                        if(HealthCareCodeInformation_09 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_09.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_09.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_09.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_10 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_10');
                        if(HealthCareCodeInformation_10 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_10.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_10.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_10.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_11 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_11');
                        if(HealthCareCodeInformation_11 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_11.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_11.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_11.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }
                        Map<String, Object> HealthCareCodeInformation_12 = (Map<String, Object>)HI_ExternalCauseofInjury.get('HealthCareCodeInformation_12');
                        if(HealthCareCodeInformation_12 != null){
                            Map<String, Object> ExtCauseOfInjury = new Map<String, Object>();
                            ExtCauseOfInjury.put('ExtCauseOfInjury.CodeListQualifierCode_01', (String)HealthCareCodeInformation_12.get('CodeListQualifierCode_01'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.IndustryCode_02', (String)HealthCareCodeInformation_12.get('IndustryCode_02'));
                            ExtCauseOfInjury.put('ExtCauseOfInjury.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_12.get('YesNoConditionorResponseCode_09'));
                            ExtCauseOfInjuryList.add(ExtCauseOfInjury);
                        }

                        objClaimInformation.put('externalCauseOfInjury', ExtCauseOfInjuryList);
                    }
                    Map<String, Object> HI_AdmittingDiagnosis = (Map<String, Object>)AllHI.get('HI_AdmittingDiagnosis');
                    if(HI_AdmittingDiagnosis != null){
                        Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)HI_AdmittingDiagnosis.get('HealthCareCodeInformation_01');
                        if(HealthCareCodeInformation_01 != null){
                            objClaimInformation.put('AdmittingDiagnosis.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                            objClaimInformation.put('AdmittingDiagnosis.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                        }
                    }
                    List<Object> HI_OtherDiagnosisInformation = (List<Object>)AllHI.get('HI_OtherDiagnosisInformation');
                    if (HI_OtherDiagnosisInformation != null) {
                        List<Object> allOtherDiagnosisCodes = new List<Object>();
                        objClaimInformation.put('otherDiagnosisCodes', allOtherDiagnosisCodes);

                        for (Object itemHI_OtherDiagnosisInformation : HI_OtherDiagnosisInformation) {
                            Map<String, Object> loopMap5 = (Map<String, Object>)itemHI_OtherDiagnosisInformation;

                            Map<String, Object> HealthCareCodeInformation_01 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_01');
                            if (HealthCareCodeInformation_01 != null) {
                                Map<String, Object> diagnosisCode = new Map<String, Object>();
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_01.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_01.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_01.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_02 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_02');
                            if (HealthCareCodeInformation_02 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_02.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_02.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_02.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_03 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_03');
                            if (HealthCareCodeInformation_03 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_03.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_03.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_03.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_04 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_04');
                            if (HealthCareCodeInformation_04 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_04.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_04.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_04.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_05 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_05');
                            if (HealthCareCodeInformation_05 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_05.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_05.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_05.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_06 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_06');
                            if (HealthCareCodeInformation_06 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_06.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_06.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_06.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_07 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_07');
                            if (HealthCareCodeInformation_07 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_07.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_07.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_07.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_08 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_08');
                            if (HealthCareCodeInformation_08 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_08.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_08.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_08.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_09 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_09');
                            if (HealthCareCodeInformation_09 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_09.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_09.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_09.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_10 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_10');
                            if (HealthCareCodeInformation_10 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_10.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_10.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_10.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_11 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_11');
                            if (HealthCareCodeInformation_11 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_11.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_11.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_11.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                            Map<String, Object> HealthCareCodeInformation_12 = (Map<String, Object>)loopMap5.get('HealthCareCodeInformation_12');
                            if (HealthCareCodeInformation_12 != null) {
                                List<Object> otherDiagnosisCodes = (List<Object>)objClaimInformation.get('otherDiagnosisCodes');
                                Map<String, Object> diagnosisCode = new Map<String, Object>();

                                diagnosisCode.put('DiagnosisCode.CodeListQualifierCode_01', (String)HealthCareCodeInformation_12.get('CodeListQualifierCode_01'));
                                diagnosisCode.put('DiagnosisCode.IndustryCode_02', (String)HealthCareCodeInformation_12.get('IndustryCode_02'));
                                diagnosisCode.put('DiagnosisCode.YesNoConditionorResponseCode_09', (String)HealthCareCodeInformation_12.get('YesNoConditionorResponseCode_09'));
                                otherDiagnosisCodes.add(diagnosisCode);
                            }
                        }
                    }
                }
				
                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.HCP_ClaimPricing_RepricingInformation
                Map<String, Object> HCP_ClaimPricing_RepricingInformation = (Map<String, Object>)loopMap3.get('HCP_ClaimPricing_RepricingInformation');
                if (HCP_ClaimPricing_RepricingInformation != null) {
                    objClaimInformation.put('ClaimPricing_RepricingInformation.PricingMethodology_01', (String)HCP_ClaimPricing_RepricingInformation.get('PricingMethodology_01'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.RepricedAllowedAmount_02', (String)HCP_ClaimPricing_RepricingInformation.get('RepricedAllowedAmount_02'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.RepricedSavingAmount_03', (String)HCP_ClaimPricing_RepricingInformation.get('RepricedSavingAmount_03'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.RepricingOrganizationIdentifier_04', (String)HCP_ClaimPricing_RepricingInformation.get('RepricingOrganizationIdentifier_04'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.RepricingPerDiemorFlatRateAmount_05', (String)HCP_ClaimPricing_RepricingInformation.get('RepricingPerDiemorFlatRateAmount_05'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.RepricedApprovedAmbulatoryPatientGroupCode_06', (String)HCP_ClaimPricing_RepricingInformation.get('RepricedApprovedAmbulatoryPatientGroupCode_06'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.MonetaryAmount_07', (String)HCP_ClaimPricing_RepricingInformation.get('MonetaryAmount_07'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.ProductServiceID_08', (String)HCP_ClaimPricing_RepricingInformation.get('ProductServiceID_08'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.ProductServiceIDQualifier_09', (String)HCP_ClaimPricing_RepricingInformation.get('ProductServiceIDQualifier_09'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.ProductServiceID_10', (String)HCP_ClaimPricing_RepricingInformation.get('ProductServiceID_10'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.UnitorBasisforMeasurementCode_11', (String)HCP_ClaimPricing_RepricingInformation.get('UnitorBasisforMeasurementCode_11'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.Quantity_12', (String)HCP_ClaimPricing_RepricingInformation.get('Quantity_12'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.RejectReasonCode_13', (String)HCP_ClaimPricing_RepricingInformation.get('RejectReasonCode_13'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.PolicyComplianceCode_14', (String)HCP_ClaimPricing_RepricingInformation.get('PolicyComplianceCode_14'));
                    objClaimInformation.put('ClaimPricing_RepricingInformation.ExceptionCode_15', (String)HCP_ClaimPricing_RepricingInformation.get('ExceptionCode_15'));
                }

                Map<String, Object> CN1_ContractInformation = (Map<String, Object>)loopMap3.get('CN1_ContractInformation');
                if (CN1_ContractInformation != null) {
                    objClaimInformation.put('ClaimInformation.ContractTypeCode_01', (String)CN1_ContractInformation.get('ContractTypeCode_01'));
                    objClaimInformation.put('ClaimInformation.ContractAmount_02', (String)CN1_ContractInformation.get('ContractAmount_02'));
                    objClaimInformation.put('ClaimInformation.ContractPercentage_03', (String)CN1_ContractInformation.get('ContractPercentage_03'));
                    objClaimInformation.put('ClaimInformation.ContractCode_04', (String)CN1_ContractInformation.get('ContractCode_04'));
                    objClaimInformation.put('ClaimInformation.TermsDiscountPercentage_05', (String)CN1_ContractInformation.get('TermsDiscountPercentage_05'));
                    objClaimInformation.put('ClaimInformation.ContractVersionIdentifier_06', (String)CN1_ContractInformation.get('ContractVersionIdentifier_06'));
                } 

                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.AllNM1
                Map<String, Object> AllNM1_4 = (Map<String, Object>)loopMap3.get('AllNM1');
                if(AllNM1_4 != null){
                    if (clmRecordType == 'Institutional') {
                        Map<String, Object> Loop2310A = (Map<String, Object>)AllNM1_4.get('Loop2310A');
                        if(Loop2310A != null){
                            Map<String, Object> NM1_AttendingProviderName = (Map<String, Object>)Loop2310A.get('NM1_AttendingProviderName');
                            objAttendingProvider.put('AttendingProviderName.EntityIdentifierCode_01', (String)NM1_AttendingProviderName.get('EntityIdentifierCode_01'));
                            objAttendingProvider.put('AttendingProviderName.EntityTypeQualifier_02', (String)NM1_AttendingProviderName.get('EntityTypeQualifier_02'));
                            objAttendingProvider.put('AttendingProviderName.ResponseContactLastorOrganizationName_03', (String)NM1_AttendingProviderName.get('ResponseContactLastorOrganizationName_03'));
                            objAttendingProvider.put('AttendingProviderName.ResponseContactFirstName_04', (String)NM1_AttendingProviderName.get('ResponseContactFirstName_04'));
                            objAttendingProvider.put('AttendingProviderName.ResponseContactMiddleName_05', (String)NM1_AttendingProviderName.get('ResponseContactMiddleName_05'));
                            objAttendingProvider.put('AttendingProviderName.NamePrefix_06', (String)NM1_AttendingProviderName.get('NamePrefix_06'));
                            objAttendingProvider.put('AttendingProviderName.ResponseContactNameSuffix_07', (String)NM1_AttendingProviderName.get('ResponseContactNameSuffix_07'));
                            objAttendingProvider.put('AttendingProviderName.IdentificationCodeQualifier_08', (String)NM1_AttendingProviderName.get('IdentificationCodeQualifier_08'));
                            objAttendingProvider.put('AttendingProviderName.EntityRelationshipCode_10', (String)NM1_AttendingProviderName.get('EntityRelationshipCode_10'));
                            objAttendingProvider.put('AttendingProviderName.EntityIdentifierCode_11', (String)NM1_AttendingProviderName.get('EntityIdentifierCode_11'));
                            objAttendingProvider.put('AttendingProviderName.NameLastorOrganizationName_12', (String)NM1_AttendingProviderName.get('NameLastorOrganizationName_12'));
                            objAttendingProvider.put('AttendingProviderName.ResponseContactIdentifier_09', (String)NM1_AttendingProviderName.get('ResponseContactIdentifier_09'));
                            output.put('attendingProviderNPI', (String)NM1_AttendingProviderName.get('ResponseContactIdentifier_09'));
                            
                            List<Object> REF_AttendingProviderSecondaryIdentification = (List<Object>)Loop2310A.get('REF_AttendingProviderSecondaryIdentification');
                            if (REF_AttendingProviderSecondaryIdentification != null) {
                                for (Object itemREF_AttendingProviderSecondaryIdentification : REF_AttendingProviderSecondaryIdentification) {
                                    Map<String, Object> loopMap4 = (Map<String, Object>)itemREF_AttendingProviderSecondaryIdentification;
    
                                    objAttendingProvider.put('AttendingProviderSecondaryIdentification.ReferenceIdentificationQualifier_01', (String)loopMap4.get('ReferenceIdentificationQualifier_01'));
                                    objAttendingProvider.put('AttendingProviderSecondaryIdentification.MemberGrouporPolicyNumber_02', (String)loopMap4.get('MemberGrouporPolicyNumber_02'));
                                    objAttendingProvider.put('AttendingProviderSecondaryIdentification.Description_03', (String)loopMap4.get('Description_03'));
                                    objAttendingProvider.put('AttendingProviderSecondaryIdentification.ReferenceIdentifier_04', (String)loopMap4.get('ReferenceIdentifier_04'));
                                }
                            }
                        }

                        Map<String, Object> Loop2310E = (Map<String, Object>)AllNM1_4.get('Loop2310E');
                        if (Loop2310E != null) {
                            Map<String, Object> NM1_ServiceFacilityLocationName = (Map<String, Object>)Loop2310E.get('NM1_ServiceFacilityLocationName');
                            objServiceFacility.put('ServiceFacilityLocationName.EntityIdentifierCode_01', (String)NM1_ServiceFacilityLocationName.get('EntityIdentifierCode_01'));
                            objServiceFacility.put('ServiceFacilityLocationName.EntityTypeQualifier_02', (String)NM1_ServiceFacilityLocationName.get('EntityTypeQualifier_02'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactLastorOrganizationName_03', (String)NM1_ServiceFacilityLocationName.get('ResponseContactLastorOrganizationName_03'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactFirstName_04', (String)NM1_ServiceFacilityLocationName.get('ResponseContactFirstName_04'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactMiddleName_05', (String)NM1_ServiceFacilityLocationName.get('ResponseContactMiddleName_05'));
                            objServiceFacility.put('ServiceFacilityLocationName.NamePrefix_06', (String)NM1_ServiceFacilityLocationName.get('NamePrefix_06'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactNameSuffix_07', (String)NM1_ServiceFacilityLocationName.get('ResponseContactNameSuffix_07'));
                            objServiceFacility.put('ServiceFacilityLocationName.IdentificationCodeQualifier_08', (String)NM1_ServiceFacilityLocationName.get('IdentificationCodeQualifier_08'));
                            objServiceFacility.put('ServiceFacilityLocationName.EntityRelationshipCode_10', (String)NM1_ServiceFacilityLocationName.get('EntityRelationshipCode_10'));
                            objServiceFacility.put('ServiceFacilityLocationName.EntityIdentifierCode_11', (String)NM1_ServiceFacilityLocationName.get('EntityIdentifierCode_11'));
                            objServiceFacility.put('ServiceFacilityLocationName.NameLastorOrganizationName_12', (String)NM1_ServiceFacilityLocationName.get('NameLastorOrganizationName_12'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactIdentifier_09', (String)NM1_ServiceFacilityLocationName.get('ResponseContactIdentifier_09'));
                            output.put('serviceFacilityNPI', (String)NM1_ServiceFacilityLocationName.get('ResponseContactIdentifier_09'));
                            Map<String, Object> N3_ServiceFacilityLocationAddress = (Map<String, Object>)Loop2310E.get('N3_ServiceFacilityLocationAddress');
                            objServiceFacility.put('ServiceFacilityLocationAddress.ResponseContactAddressLine_01', (String)N3_ServiceFacilityLocationAddress.get('ResponseContactAddressLine_01'));
                            objServiceFacility.put('ServiceFacilityLocationAddress.ResponseContactAddressLine_02', (String)N3_ServiceFacilityLocationAddress.get('ResponseContactAddressLine_02'));
                            Map<String, Object> N4_ServiceFacilityLocationCity_State_ZIP = (Map<String, Object>)Loop2310E.get('N4_ServiceFacilityLocationCity_State_ZIP');
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01', (String)N4_ServiceFacilityLocationCity_State_ZIP.get('AdditionalPatientInformationContactCityName_01'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02', (String)N4_ServiceFacilityLocationCity_State_ZIP.get('N4_ServiceFacilityLocationCity_State_ZIPCode'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.AdditionalPatientInformationContactPostalZoneorZIPCode_03', (String)N4_ServiceFacilityLocationCity_State_ZIP.get('AdditionalPatientInformationContactPostalZoneorZIPCode_03'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.CountryCode_04', (String)N4_ServiceFacilityLocationCity_State_ZIP.get('CountryCode_04'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.LocationQualifier_05', (String)N4_ServiceFacilityLocationCity_State_ZIP.get('LocationQualifier_05'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.LocationIdentifier_06', (String)N4_ServiceFacilityLocationCity_State_ZIP.get('LocationIdentifier_06'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.CountrySubdivisionCode_07', (String)N4_ServiceFacilityLocationCity_State_ZIP.get('CountrySubdivisionCode_07'));
                        }
                    }else if (clmRecordType == 'Professional'){
                        List<Object> Loop2310A = (List<Object>)AllNM1_4.get('Loop2310A');
                        if (Loop2310A != null) {
                            for (Object itemLoop2310A : Loop2310A) {
                                Map<String, Object> loopMap4 = (Map<String, Object>)itemLoop2310A;

                                Map<String, Object> NM1_ReferringProviderName = (Map<String, Object>)loopMap4.get('NM1_ReferringProviderName');
                                objReferringProvider.put('ReferringProviderName.EntityIdentifierCode_01', (String)NM1_ReferringProviderName.get('EntityIdentifierCode_01'));
                                objReferringProvider.put('ReferringProviderName.EntityTypeQualifier_02', (String)NM1_ReferringProviderName.get('EntityTypeQualifier_02'));
                                objReferringProvider.put('ReferringProviderName.ResponseContactLastorOrganizationName_03', (String)NM1_ReferringProviderName.get('ResponseContactLastorOrganizationName_03'));
                                objReferringProvider.put('ReferringProviderName.ResponseContactFirstName_04', (String)NM1_ReferringProviderName.get('ResponseContactFirstName_04'));
                                objReferringProvider.put('ReferringProviderName.ResponseContactMiddleName_05', (String)NM1_ReferringProviderName.get('ResponseContactMiddleName_05'));
                                objReferringProvider.put('ReferringProviderName.NamePrefix_06', (String)NM1_ReferringProviderName.get('NamePrefix_06'));
                                objReferringProvider.put('ReferringProviderName.ResponseContactNameSuffix_07', (String)NM1_ReferringProviderName.get('ResponseContactNameSuffix_07'));
                                objReferringProvider.put('ReferringProviderName.IdentificationCodeQualifier_08', (String)NM1_ReferringProviderName.get('IdentificationCodeQualifier_08'));
                                objReferringProvider.put('ReferringProviderName.EntityRelationshipCode_10', (String)NM1_ReferringProviderName.get('EntityRelationshipCode_10'));
                                objReferringProvider.put('ReferringProviderName.EntityIdentifierCode_11', (String)NM1_ReferringProviderName.get('EntityIdentifierCode_11'));
                                objReferringProvider.put('ReferringProviderName.NameLastorOrganizationName_12', (String)NM1_ReferringProviderName.get('NameLastorOrganizationName_12'));
                                objReferringProvider.put('ReferringProviderName.ResponseContactIdentifier_09', (String)NM1_ReferringProviderName.get('ResponseContactIdentifier_09'));
                                output.put('referringProviderNPI', (String)NM1_ReferringProviderName.get('ResponseContactIdentifier_09'));
                            }
                        }

                        Map<String, Object> Loop2310B = (Map<String, Object>)AllNM1_4.get('Loop2310B');
                        if (Loop2310B != null) {
                            Map<String, Object> NM1_RenderingProviderName = (Map<String, Object>)Loop2310B.get('NM1_RenderingProviderName');
                            if (NM1_RenderingProviderName != null) {
                                objRenderingProvider.put('RenderingProviderName.EntityIdentifierCode_01', (String)NM1_RenderingProviderName.get('EntityIdentifierCode_01'));
                                objRenderingProvider.put('RenderingProviderName.EntityTypeQualifier_02', (String)NM1_RenderingProviderName.get('EntityTypeQualifier_02'));
                                objRenderingProvider.put('RenderingProviderName.ResponseContactLastorOrganizationName_03', (String)NM1_RenderingProviderName.get('ResponseContactLastorOrganizationName_03'));
                                objRenderingProvider.put('RenderingProviderName.ResponseContactFirstName_04', (String)NM1_RenderingProviderName.get('ResponseContactFirstName_04'));
                                objRenderingProvider.put('RenderingProviderName.ResponseContactMiddleName_05', (String)NM1_RenderingProviderName.get('ResponseContactMiddleName_05'));
                                objRenderingProvider.put('RenderingProviderName.NamePrefix_06', (String)NM1_RenderingProviderName.get('NamePrefix_06'));
                                objRenderingProvider.put('RenderingProviderName.ResponseContactNameSuffix_07', (String)NM1_RenderingProviderName.get('ResponseContactNameSuffix_07'));
                                objRenderingProvider.put('RenderingProviderName.IdentificationCodeQualifier_08', (String)NM1_RenderingProviderName.get('IdentificationCodeQualifier_08'));
                                objRenderingProvider.put('RenderingProviderName.EntityRelationshipCode_10', (String)NM1_RenderingProviderName.get('EntityRelationshipCode_10'));
                                objRenderingProvider.put('RenderingProviderName.EntityIdentifierCode_11', (String)NM1_RenderingProviderName.get('EntityIdentifierCode_11'));
                                objRenderingProvider.put('RenderingProviderName.NameLastorOrganizationName_12', (String)NM1_RenderingProviderName.get('NameLastorOrganizationName_12'));
                                objRenderingProvider.put('RenderingProviderName.ResponseContactIdentifier_09', (String)NM1_RenderingProviderName.get('NameLastorOrganizationName_12'));
                                output.put('renderingProviderNPI', (String)NM1_RenderingProviderName.get('ResponseContactIdentifier_09'));
                            }
                        }

                        Map<String, Object> Loop2310C = (Map<String, Object>)AllNM1_4.get('Loop2310C');
                        if (Loop2310C != null) {
                            Map<String, Object> NM1_ServiceFacilityLocationName_2 = (Map<String, Object>)Loop2310C.get('NM1_ServiceFacilityLocationName');
                            objServiceFacility.put('ServiceFacilityLocationName.EntityIdentifierCode_01', (String)NM1_ServiceFacilityLocationName_2.get('EntityIdentifierCode_01'));
                            objServiceFacility.put('ServiceFacilityLocationName.EntityTypeQualifier_02', (String)NM1_ServiceFacilityLocationName_2.get('EntityTypeQualifier_02'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactLastorOrganizationName_03', (String)NM1_ServiceFacilityLocationName_2.get('ResponseContactLastorOrganizationName_03'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactFirstName_04', (String)NM1_ServiceFacilityLocationName_2.get('ResponseContactFirstName_04'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactMiddleName_05', (String)NM1_ServiceFacilityLocationName_2.get('ResponseContactMiddleName_05'));
                            objServiceFacility.put('ServiceFacilityLocationName.NamePrefix_06', (String)NM1_ServiceFacilityLocationName_2.get('NamePrefix_06'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactNameSuffix_07', (String)NM1_ServiceFacilityLocationName_2.get('ResponseContactNameSuffix_07'));
                            objServiceFacility.put('ServiceFacilityLocationName.IdentificationCodeQualifier_08', (String)NM1_ServiceFacilityLocationName_2.get('IdentificationCodeQualifier_08'));
                            objServiceFacility.put('ServiceFacilityLocationName.EntityRelationshipCode_10', (String)NM1_ServiceFacilityLocationName_2.get('EntityRelationshipCode_10'));
                            objServiceFacility.put('ServiceFacilityLocationName.EntityIdentifierCode_11', (String)NM1_ServiceFacilityLocationName_2.get('EntityIdentifierCode_11'));
                            objServiceFacility.put('ServiceFacilityLocationName.NameLastorOrganizationName_12', (String)NM1_ServiceFacilityLocationName_2.get('NameLastorOrganizationName_12'));
                            objServiceFacility.put('ServiceFacilityLocationName.ResponseContactIdentifier_09', (String)NM1_ServiceFacilityLocationName_2.get('ResponseContactIdentifier_09'));
                            output.put('serviceFacilityNPI', (String)NM1_ServiceFacilityLocationName_2.get('ResponseContactIdentifier_09'));
                            Map<String, Object> N3_ServiceFacilityLocationAddress_2 = (Map<String, Object>)Loop2310C.get('N3_ServiceFacilityLocationAddress');
                            objServiceFacility.put('ServiceFacilityLocationAddress.ResponseContactAddressLine_01', (String)N3_ServiceFacilityLocationAddress_2.get('ResponseContactAddressLine_01'));
                            objServiceFacility.put('ServiceFacilityLocationAddress.ResponseContactAddressLine_02', (String)N3_ServiceFacilityLocationAddress_2.get('ResponseContactAddressLine_02'));
                            Map<String, Object> N4_ServiceFacilityLocationCity_State_ZIPCode = (Map<String, Object>)Loop2310C.get('N4_ServiceFacilityLocationCity_State_ZIPCode');
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.AdditionalPatientInformationContactCityName_01', (String)N4_ServiceFacilityLocationCity_State_ZIPCode.get('AdditionalPatientInformationContactCityName_01'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.AdditionalPatientInformationContactStateCode_02', (String)N4_ServiceFacilityLocationCity_State_ZIPCode.get('N4_ServiceFacilityLocationCity_State_ZIPCode'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.AdditionalPatientInformationContactPostalZoneorZIPCode_03', (String)N4_ServiceFacilityLocationCity_State_ZIPCode.get('AdditionalPatientInformationContactPostalZoneorZIPCode_03'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.CountryCode_04', (String)N4_ServiceFacilityLocationCity_State_ZIPCode.get('CountryCode_04'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.LocationQualifier_05', (String)N4_ServiceFacilityLocationCity_State_ZIPCode.get('LocationQualifier_05'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.LocationIdentifier_06', (String)N4_ServiceFacilityLocationCity_State_ZIPCode.get('LocationIdentifier_06'));
                            objServiceFacility.put('ServiceFacilityLocationCity_State_ZIPCode.CountrySubdivisionCode_07', (String)N4_ServiceFacilityLocationCity_State_ZIPCode.get('CountrySubdivisionCode_07'));
                        }
                    }
                }
                
                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.Loop2320 - Other Subscriber (COB) Information
                List<Object> Loop2320 = (List<Object>)loopMap3.get('Loop2320');
                if (Loop2320 != null) {
                    List<Object> otherSubscriberList = new List<Object>();
                    
                    for (Object itemLoop2320 : Loop2320) {
                        Map<String, Object> loopMap2320 = (Map<String, Object>)itemLoop2320;
                        Map<String, Object> otherSubscriber = new Map<String, Object>();
                        
                        // Get filing indicator code to identify Medicare
                        Map<String, Object> SBR_OtherSubscriberInformation = (Map<String, Object>)loopMap2320.get('SBR_OtherSubscriberInformation');
                        if (SBR_OtherSubscriberInformation != null) {
                            otherSubscriber.put('ClaimFilingIndicatorCode', SBR_OtherSubscriberInformation.get('ClaimFilingIndicatorCode_09'));
                        }
                        
                        // Get payer ID from Loop2330B
                        Map<String, Object> AllNM1_2320 = (Map<String, Object>)loopMap2320.get('AllNM1');
                        if (AllNM1_2320 != null) {
                            Map<String, Object> Loop2330B = (Map<String, Object>)AllNM1_2320.get('Loop2330B');
                            if (Loop2330B != null) {
                                Map<String, Object> NM1_OtherPayerName = (Map<String, Object>)Loop2330B.get('NM1_OtherPayerName');
                                if (NM1_OtherPayerName != null) {
                                    otherSubscriber.put('PayerID', NM1_OtherPayerName.get('ResponseContactIdentifier_09'));
                                }
                            }
                        }
                        
                        otherSubscriberList.add(otherSubscriber);
                    }
                    
                    objClaimInformation.put('otherSubscriberInfo', otherSubscriberList);
                }
				
                // Groups.Transactions.Loop2000A.Loop2000B.Loop2300.Loop2400
                List<Object> Loop2400 = (List<Object>)loopMap3.get('Loop2400');
                for (Object itemLoop2400 : Loop2400) {
                    Map<String, Object> loopMap4 = (Map<String, Object>)itemLoop2400;
                    Map<String, Object> objClaimLineItem = new Map<String, Object>();
                    
                    Map<String, Object> LX_ServiceLineNumber = (Map<String, Object>)loopMap4.get('LX_ServiceLineNumber');
                    objClaimLineItem.put('ServiceLineNumber.AssignedNumber_01', (String)LX_ServiceLineNumber.get('AssignedNumber_01'));

                    Map<String, Object> HCP_LinePricing_RepricingInformation = (Map<String, Object>)loopMap4.get('HCP_LinePricing_RepricingInformation');
                    if (HCP_LinePricing_RepricingInformation != null) {
                        objClaimLineItem.put('LinePricing_RepricingInformation.PricingMethodology_01', (String)HCP_LinePricing_RepricingInformation.get('PricingMethodology_01'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.RepricedAllowedAmount_02', (String)HCP_LinePricing_RepricingInformation.get('RepricedAllowedAmount_02'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.RepricedSavingAmount_03', (String)HCP_LinePricing_RepricingInformation.get('RepricedSavingAmount_03'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.RepricingOrganizationIdentifier_04', (String)HCP_LinePricing_RepricingInformation.get('RepricingOrganizationIdentifier_04'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.RepricingPerDiemorFlatRateAmount_05', (String)HCP_LinePricing_RepricingInformation.get('RepricingPerDiemorFlatRateAmount_05'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.RepricedApprovedAmbulatoryPatientGroupCode_06', (String)HCP_LinePricing_RepricingInformation.get('RepricedApprovedAmbulatoryPatientGroupCode_06'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.MonetaryAmount_07', (String)HCP_LinePricing_RepricingInformation.get('MonetaryAmount_07'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.ProductServiceID_08', (String)HCP_LinePricing_RepricingInformation.get('ProductServiceID_08'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.ProductServiceIDQualifier_09', (String)HCP_LinePricing_RepricingInformation.get('ProductServiceIDQualifier_09'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.ProductServiceID_10', (String)HCP_LinePricing_RepricingInformation.get('ProductServiceID_10'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.UnitorBasisforMeasurementCode_11', (String)HCP_LinePricing_RepricingInformation.get('UnitorBasisforMeasurementCode_11'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.Quantity_12', (String)HCP_LinePricing_RepricingInformation.get('Quantity_12'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.RejectReasonCode_13', (String)HCP_LinePricing_RepricingInformation.get('RejectReasonCode_13'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.PolicyComplianceCode_14', (String)HCP_LinePricing_RepricingInformation.get('PolicyComplianceCode_14'));
                        objClaimLineItem.put('LinePricing_RepricingInformation.ExceptionCode_15', (String)HCP_LinePricing_RepricingInformation.get('ExceptionCode_15'));
                    }

                    if(clmRecordType == 'Institutional'){
                        Map<String, Object> SV2_InstitutionalServiceLine = (Map<String, Object>)loopMap4.get('SV2_InstitutionalServiceLine');
                        if (SV2_InstitutionalServiceLine != null) {
                            objClaimLineItem.put('InstitutionalServiceLine.ServiceLineRevenueCode_01', (String)SV2_InstitutionalServiceLine.get('ServiceLineRevenueCode_01'));
                            objClaimLineItem.put('InstitutionalServiceLine.LineItemChargeAmount_03', (String)SV2_InstitutionalServiceLine.get('LineItemChargeAmount_03'));
                            objClaimLineItem.put('InstitutionalServiceLine.UnitorBasisforMeasurementCode_04', (String)SV2_InstitutionalServiceLine.get('UnitorBasisforMeasurementCode_04'));
                            objClaimLineItem.put('InstitutionalServiceLine.ServiceUnitCount_05', (String)SV2_InstitutionalServiceLine.get('ServiceUnitCount_05'));
                            Map<String, Object> CompositeMedicalProcedureIdentifier_02 = (Map<String, Object>)SV2_InstitutionalServiceLine.get('CompositeMedicalProcedureIdentifier_02');
                            if (CompositeMedicalProcedureIdentifier_02 != null) {
                                objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProductorServiceIDQualifier_01', (String)CompositeMedicalProcedureIdentifier_02.get('ProductorServiceIDQualifier_01'));
                                objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureCode_02', (String)CompositeMedicalProcedureIdentifier_02.get('ProcedureCode_02'));
                                objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureModifier_03', (String)CompositeMedicalProcedureIdentifier_02.get('ProcedureModifier_03'));
                                objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureModifier_04', (String)CompositeMedicalProcedureIdentifier_02.get('ProcedureModifier_04'));
                                objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureModifier_05', (String)CompositeMedicalProcedureIdentifier_02.get('ProcedureModifier_05'));
                                objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureModifier_06', (String)CompositeMedicalProcedureIdentifier_02.get('ProcedureModifier_06'));
                            }
                        }

                        Map<String, Object> DTP_Date_ServiceDate = (Map<String, Object>)loopMap4.get('DTP_Date_ServiceDate');
                        if (DTP_Date_ServiceDate != null) {
                            objClaimLineItem.put('ServiceDate.DateTimeQualifier_01', (String)DTP_Date_ServiceDate.get('DateTimeQualifier_01'));
                            objClaimLineItem.put('ServiceDate.DateTimePeriodFormatQualifier_02', (String)DTP_Date_ServiceDate.get('DateTimePeriodFormatQualifier_02'));
                            objClaimLineItem.put('ServiceDate.DateTimePeriod_03', (String)DTP_Date_ServiceDate.get('DateTimePeriod_03'));
                            objClaimInformation.put('ServiceDateFromLineItem', (String)DTP_Date_ServiceDate.get('DateTimePeriod_03'));
                        }
                    }else if(clmRecordType == 'Professional'){
                        Map<String, Object> SV1_ProfessionalService = (Map<String, Object>)loopMap4.get('SV1_ProfessionalService');
                        objClaimLineItem.put('ProfessionalService.LineItemChargeAmount_02', (String)SV1_ProfessionalService.get('LineItemChargeAmount_02'));
                        objClaimLineItem.put('ProfessionalService.UnitorBasisforMeasurementCode_03', (String)SV1_ProfessionalService.get('UnitorBasisforMeasurementCode_03'));
                        objClaimLineItem.put('ProfessionalService.ServiceUnitCount_04', (String)SV1_ProfessionalService.get('ServiceUnitCount_04'));
                        objClaimLineItem.put('ProfessionalService.PlaceofServiceCode_05', (String)SV1_ProfessionalService.get('PlaceofServiceCode_05'));
                        objClaimLineItem.put('ProfessionalService.ServiceTypeCode_06', (String)SV1_ProfessionalService.get('ServiceTypeCode_06'));
                        objClaimLineItem.put('ProfessionalService.MonetaryAmount_08', (String)SV1_ProfessionalService.get('MonetaryAmount_08'));
                        objClaimLineItem.put('ProfessionalService.EmergencyIndicator_09', (String)SV1_ProfessionalService.get('EmergencyIndicator_09'));
                        objClaimLineItem.put('ProfessionalService.MultipleProcedureCode_10', (String)SV1_ProfessionalService.get('MultipleProcedureCode_10'));
                        objClaimLineItem.put('ProfessionalService.EPSDTIndicator_11', (String)SV1_ProfessionalService.get('EPSDTIndicator_11'));
                        objClaimLineItem.put('ProfessionalService.FamilyPlanningIndicator_12', (String)SV1_ProfessionalService.get('FamilyPlanningIndicator_12'));
                        objClaimLineItem.put('ProfessionalService.ReviewCode_13', (String)SV1_ProfessionalService.get('ReviewCode_13'));
                        objClaimLineItem.put('ProfessionalService.NationalorLocalAssignedReviewValue_14', (String)SV1_ProfessionalService.get('NationalorLocalAssignedReviewValue_14'));
                        objClaimLineItem.put('ProfessionalService.CoPayStatusCode_15', (String)SV1_ProfessionalService.get('CoPayStatusCode_15'));
                        objClaimLineItem.put('ProfessionalService.HealthCareProfessionalShortageAreaCode_16', (String)SV1_ProfessionalService.get('HealthCareProfessionalShortageAreaCode_16'));
                        objClaimLineItem.put('ProfessionalService.ReferenceIdentification_17', (String)SV1_ProfessionalService.get('ReferenceIdentification_17'));
                        objClaimLineItem.put('ProfessionalService.PostalCode_18', (String)SV1_ProfessionalService.get('PostalCode_18'));
                        objClaimLineItem.put('ProfessionalService.MonetaryAmount_19', (String)SV1_ProfessionalService.get('MonetaryAmount_19'));
                        objClaimLineItem.put('ProfessionalService.LevelofCareCode_20', (String)SV1_ProfessionalService.get('LevelofCareCode_20'));
                        objClaimLineItem.put('ProfessionalService.ProviderAgreementCode_21', (String)SV1_ProfessionalService.get('ProviderAgreementCode_21'));
                        Map<String, Object> CompositeMedicalProcedureIdentifier_01 = (Map<String, Object>)SV1_ProfessionalService.get('CompositeMedicalProcedureIdentifier_01');
                        if (CompositeMedicalProcedureIdentifier_01 != null) {
                            objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProductorServiceIDQualifier_01', (String)CompositeMedicalProcedureIdentifier_01.get('ProductorServiceIDQualifier_01'));
                            objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureCode_02', (String)CompositeMedicalProcedureIdentifier_01.get('ProcedureCode_02'));
                            objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureModifier_03', (String)CompositeMedicalProcedureIdentifier_01.get('ProcedureModifier_03'));
                            objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureModifier_04', (String)CompositeMedicalProcedureIdentifier_01.get('ProcedureModifier_04'));
                            objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureModifier_05', (String)CompositeMedicalProcedureIdentifier_01.get('ProcedureModifier_05'));
                            objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProcedureModifier_06', (String)CompositeMedicalProcedureIdentifier_01.get('ProcedureModifier_06'));
                            objClaimLineItem.put('CompositeMedicalProcedureIdentifier.Description_07', (String)CompositeMedicalProcedureIdentifier_01.get('Description_07'));
                            objClaimLineItem.put('CompositeMedicalProcedureIdentifier.ProductServiceID_08', (String)CompositeMedicalProcedureIdentifier_01.get('ProductServiceID_08'));
                        }
                        Map<String, Object> CompositeDiagnosisCodePointer_07 = (Map<String, Object>)SV1_ProfessionalService.get('CompositeDiagnosisCodePointer_07');
                        if (CompositeDiagnosisCodePointer_07 != null) {
                            objClaimLineItem.put('CompositeDiagnosisCodePointer.DiagnosisCodePointer_01', (String)CompositeDiagnosisCodePointer_07.get('DiagnosisCodePointer_01'));
                            objClaimLineItem.put('CompositeDiagnosisCodePointer.DiagnosisCodePointer_02', (String)CompositeDiagnosisCodePointer_07.get('DiagnosisCodePointer_02'));
                            objClaimLineItem.put('CompositeDiagnosisCodePointer.DiagnosisCodePointer_03', (String)CompositeDiagnosisCodePointer_07.get('DiagnosisCodePointer_03'));
                            objClaimLineItem.put('CompositeDiagnosisCodePointer.DiagnosisCodePointer_04', (String)CompositeDiagnosisCodePointer_07.get('DiagnosisCodePointer_04'));
                        }

                        Map<String, Object> AllDTP_2 = (Map<String, Object>)loopMap4.get('AllDTP');
                        if (AllDTP_2 != null) {
                            // objClaimLineItem.put('DTP_Date_PrescriptionDate', (String)AllDTP_2.get('DTP_Date_PrescriptionDate'));
                            // objClaimLineItem.put('DTP_DATE_CertificationRevision_RecertificationDate', (String)AllDTP_2.get('DTP_DATE_CertificationRevision_RecertificationDate'));
                            // objClaimLineItem.put('DTP_Date_BeginTherapyDate', (String)AllDTP_2.get('DTP_Date_BeginTherapyDate'));
                            // objClaimLineItem.put('DTP_Date_LastCertificationDate', (String)AllDTP_2.get('DTP_Date_LastCertificationDate'));
                            // objClaimLineItem.put('DTP_Date_LastSeenDate', (String)AllDTP_2.get('DTP_Date_LastSeenDate'));
                            // objClaimLineItem.put('DTP_Date_TestDate', (String)AllDTP_2.get('DTP_Date_TestDate'));
                            // objClaimLineItem.put('DTP_Date_ShippedDate', (String)AllDTP_2.get('DTP_Date_ShippedDate'));
                            // objClaimLineItem.put('DTP_Date_LastX_Date', (String)AllDTP_2.get('DTP_Date_LastX_Date'));
                            // objClaimLineItem.put('DTP_Date_InitialTreatmentDate', (String)AllDTP_2.get('DTP_Date_InitialTreatmentDate'));
                            Map<String, Object> DTP_Date_ServiceDate = (Map<String, Object>)AllDTP_2.get('DTP_Date_ServiceDate');
                            if (DTP_Date_ServiceDate != null) {
                                objClaimLineItem.put('ServiceDate.DateTimeQualifier_01', (String)DTP_Date_ServiceDate.get('DateTimeQualifier_01'));
                                objClaimLineItem.put('ServiceDate.DateTimePeriodFormatQualifier_02', (String)DTP_Date_ServiceDate.get('DateTimePeriodFormatQualifier_02'));
                                objClaimLineItem.put('ServiceDate.DateTimePeriod_03', (String)DTP_Date_ServiceDate.get('DateTimePeriod_03'));
                                objClaimInformation.put('ServiceDateFromLineItem', (String)DTP_Date_ServiceDate.get('DateTimePeriod_03'));
                            }
                        }
                    }
                    
                    // Process Loop2430 - Line Level COB/Medicare Adjudication
                    List<Object> Loop2430 = (List<Object>)loopMap4.get('Loop2430');
                    if (Loop2430 != null && !Loop2430.isEmpty()) {
                        // We'll typically have one Loop2430 per line for Medicare
                        // but process as a list in case there are multiple payers
                        List<Map<String, Object>> lineAdjudicationList = new List<Map<String, Object>>();
                        
                        for (Object itemLoop2430 : Loop2430) {
                            Map<String, Object> loopMap2430 = (Map<String, Object>)itemLoop2430;
                            Map<String, Object> lineAdjudication = new Map<String, Object>();
                            
                            // SVD - Service Line Adjudication Information
                            Map<String, Object> SVD_LineAdj = (Map<String, Object>)loopMap2430.get('SVD_LineAdjudicationInformation');
                            if (SVD_LineAdj != null) {
                                // Get the other payer ID and paid amount
                                lineAdjudication.put('OtherPayerID', (String)SVD_LineAdj.get('OtherPayerPrimaryIdentifier_01'));
                                String paidAmount = (String)SVD_LineAdj.get('ServiceLinePaidAmount_02');
                                lineAdjudication.put('LinePaidAmount', paidAmount);
                                
                                // Get procedure info to verify it matches
                                Map<String, Object> procIdentifier = (Map<String, Object>)SVD_LineAdj.get('CompositeMedicalProcedureIdentifier_03');
                                if (procIdentifier != null) {
                                    lineAdjudication.put('AdjudicatedProcedureCode', (String)procIdentifier.get('ProcedureCode_02'));
                                    lineAdjudication.put('AdjudicatedModifier1', (String)procIdentifier.get('ProcedureModifier_03'));
                                    lineAdjudication.put('AdjudicatedModifier2', (String)procIdentifier.get('ProcedureModifier_04'));
                                    lineAdjudication.put('AdjudicatedModifier3', (String)procIdentifier.get('ProcedureModifier_05'));
                                    lineAdjudication.put('AdjudicatedModifier4', (String)procIdentifier.get('ProcedureModifier_06'));
                                }
                                
                                lineAdjudication.put('PaidServiceUnitCount', (String)SVD_LineAdj.get('PaidServiceUnitCount_05'));
                            }
                            
                            // CAS - Claim Adjustment Segments (calculate member liability and allowed amount)
                            Decimal totalMemberLiability = 0;
                            Decimal totalContractualAdjustment = 0;
                            List<Map<String, Object>> adjustmentsList = new List<Map<String, Object>>();
                            
                            List<Object> CAS_LineAdj = (List<Object>)loopMap2430.get('CAS_LineAdjustment');
                            if (CAS_LineAdj != null) {
                                System.debug('=== CAS_LineAdj size: ' + CAS_LineAdj.size());
                                
                                for (Object cas : CAS_LineAdj) {
                                    Map<String, Object> casMap = (Map<String, Object>)cas;
                                    System.debug('=== CAS Map Keys: ' + casMap.keySet());
                                    String groupCode = (String)casMap.get('ClaimAdjustmentGroupCode_01');
                                    System.debug('=== Group Code: ' + groupCode);
                                    
                                    // Process up to 6 adjustment reason/amount pairs per CAS segment
                                    for (Integer i = 0; i < 6; i++) {
                                        Integer reasonOffset = 2 + (i * 3);
                                        Integer amountOffset = 3 + (i * 3);
                                        
                                        String reasonKey = 'AdjustmentReasonCode_' + String.valueOf(reasonOffset).leftPad(2, '0');
										String amountKey = 'AdjustmentAmount_' + String.valueOf(amountOffset).leftPad(2, '0');
                                        
                                        System.debug('=== Looking for keys: ' + reasonKey + ' and ' + amountKey);
                                        
                                        String reasonCode = (String)casMap.get(reasonKey);
                                        Object amountObj = casMap.get(amountKey);
                                        
                                        System.debug('=== Reason Code: ' + reasonCode);
                                        System.debug('=== Amount Object: ' + amountObj);
                                        // Check type using instanceof
                                        if (amountObj != null) {
                                            if (amountObj instanceof String) {
                                                System.debug('=== Amount is String');
                                            } else if (amountObj instanceof Decimal) {
                                                System.debug('=== Amount is Decimal');
                                            } else if (amountObj instanceof Double) {
                                                System.debug('=== Amount is Double');
                                            } else if (amountObj instanceof Integer) {
                                                System.debug('=== Amount is Integer');
                                            } else {
                                                System.debug('=== Amount is unknown type');
                                            }
                                        }
                                        
                                        if (String.isNotBlank(reasonCode) && amountObj != null) {
                                            String amountStr = String.valueOf(amountObj);
                                            System.debug('=== Amount String: ' + amountStr);
                                            
                                            try {
                                                Decimal amount = Decimal.valueOf(amountStr);
                                                
                                                // Create adjustment record
                                                Map<String, Object> adjustment = new Map<String, Object>();
                                                adjustment.put('GroupCode', groupCode);
                                                adjustment.put('ReasonCode', reasonCode);
                                                adjustment.put('Amount', amountStr);
                                                adjustmentsList.add(adjustment);
                                                
                                                // Sum by group code
                                                if ('PR'.equals(groupCode)) {
                                                    // PR = Patient Responsibility
                                                    totalMemberLiability += amount;
                                                } else if ('CO'.equals(groupCode)) {
                                                    // CO = Contractual Obligation
                                                    totalContractualAdjustment += amount;
                                                }
                                                // OA (Other Adjustments) and other codes are tracked but not summed here
                                                
                                            } catch (Exception e) {
                                                System.debug('Error parsing adjustment amount: ' + e.getMessage());
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Store all adjustments
                            lineAdjudication.put('Adjustments', adjustmentsList);
                            lineAdjudication.put('MemberLiability', String.valueOf(totalMemberLiability));
                            lineAdjudication.put('ContractualAdjustment', String.valueOf(totalContractualAdjustment));
                            
                            // Calculate Medicare Allowed Amount
                            Decimal medicarePaid = 0;
                            try {
                                String paidAmountStr = (String)lineAdjudication.get('LinePaidAmount');
                                if (String.isNotBlank(paidAmountStr)) {
                                    medicarePaid = Decimal.valueOf(paidAmountStr);
                                }
                            } catch (Exception e) {
                                System.debug('Error parsing Medicare paid amount: ' + e.getMessage());
                            }
                            
                            Decimal medicareAllowed = medicarePaid + totalMemberLiability;
                            lineAdjudication.put('MedicareAllowed', String.valueOf(medicareAllowed));
                            
                            // DTP - Check or Remittance Date
                            Map<String, Object> DTP_RemittanceDate = (Map<String, Object>)loopMap2430.get('DTP_LineCheckorRemittanceDate');
                            if (DTP_RemittanceDate != null) {
                                lineAdjudication.put('RemittanceDate', (String)DTP_RemittanceDate.get('DateTimePeriod_03'));
                            }
                            
                            lineAdjudicationList.add(lineAdjudication);
                        }
                        
                        // Add to line item
                        objClaimLineItem.put('otherPayerLineAdjudication', lineAdjudicationList);
                    }
                      
                    claimLineItemsList.add(objClaimLineItem);
                }
            }
        }

        output.put('claimInformation', objClaimInformation);
        output.put('referringProvider', objReferringProvider);
        output.put('serviceFacility', objServiceFacility);
        output.put('lineItems', claimLineItemsList);
        if (clmRecordType == 'Professional') {
            output.put('renderingProvider', objRenderingProvider);

            output.put('professional', true);
            output.put('institutional', false);
        }else if(clmRecordType == 'Institutional'){
            output.put('attendingProvider', objAttendingProvider);

            output.put('professional', false);
            output.put('institutional', true);
        }

        return output;
    }
}