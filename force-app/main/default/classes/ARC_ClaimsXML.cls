public with sharing class ARC_ClaimsXML {

    public static String generate(Map <String, Object> inputMap) {
        Boolean isProvider = (Boolean)inputMap.get('isProvider');
        Integer inboundDocumentIdentifier = (Integer)inputMap.get('inboundDocumentIdentifier');
        Claim c = (Claim)inputMap.get('claim');
        // delete duplicate information in Claim Name for EOB
        c.Name = c.Name.replaceAll(' - \\(DUPLICATE\\)', '')
                .replaceAll('\\(DUPLICATE\\)', '')
                .replaceAll(' - \\(PARTIAL DUPLICATE\\)', '')
                .replaceAll('\\(PARTIAL DUPLICATE\\)', '')
                .trim();
        Contact cont = (Contact)inputMap.get('contact');
        List<ClaimCoveragePaymentDetail> listCCPD = (List<ClaimCoveragePaymentDetail>)inputMap.get('listCCPD');
        List<ClaimCoveragePaymentDetail> listAdjCCPD = (List<ClaimCoveragePaymentDetail>)inputMap.get('listAdjCCPD');
        Boolean checkClosing = (Boolean)inputMap.get('checkClosing');
        // Start document
        String XML_Claim = '<document inboundDocumentIdentifier="' + inboundDocumentIdentifier + '">\n';
        
        // Create the map to store fieldNames and values
        Map<String, String> mapFieldNamesValue = new Map<String,String>();
        
        // Start recordType 00 - 8 nodes
        mapFieldNamesValue.clear();
        //create cRecipientCode for Provider or Member 
        if(isProvider){ 
            if(c?.ARC_Vendor__r?.Name != null) {
                mapFieldNamesValue.put('cName', (String)c.ARC_Vendor__r.Name.substring(0,Math.min(c.ARC_Vendor__r.Name.length(), 50)));
            }
            else if(c?.ARC_Attending_Provider__r?.Name != null){
                mapFieldNamesValue.put('cName', (String)c.ARC_Attending_Provider__r.Name.substring(0,Math.min(c.ARC_Attending_Provider__r.Name.length(), 50)));
            }


            if(c?.ARC_PayToStreet__c != null) mapFieldNamesValue.put('cAddress1', (String) c?.ARC_PayToStreet__c.substring(0,c?.ARC_PayToStreet__c.length() <= 80 ? c?.ARC_PayToStreet__c.length():80));
            if(c?.ARC_PayToCity__c != null) mapFieldNamesValue.put('cCity', (String)c?.ARC_PayToCity__c.substring(0,c?.ARC_PayToCity__c.length() <=30? c?.ARC_PayToCity__c.length(): 30));
            if(c?.ARC_PayTo_State__c != null) mapFieldNamesValue.put('cState', (String)c?.ARC_PayTo_State__c.substring(0,c?.ARC_PayTo_State__c.length() <=2? c?.ARC_PayTo_State__c.length():2));
            if(c?.ARC_PayTo_ZipCode__c!= null) mapFieldNamesValue.put('cZip', (String)c?.ARC_PayTo_ZipCode__c.substring(0,c?.ARC_PayTo_ZipCode__c.length()<=5? c?.ARC_PayTo_ZipCode__c.length():5));       
            mapFieldNamesValue.put('cRecipientCode', 'P');
            if(c?.ARC_Payment_To__c != null && c?.ARC_Payment_To__c=='Provider' && c?.ARC_TotalNetPaidAmount__c != null && c?.ARC_TotalNetPaidAmount__c>0 && checkClosing)mapFieldNamesValue.put('cDocumentType', '011'); // Provider/Check
            else mapFieldNamesValue.put('cDocumentType', '010');//Provider remit only
        }
        else {
            if(c?.ARC_PrimaryMemberCM__r?.Name != null)  mapFieldNamesValue.put('cName', (String) c?.ARC_PrimaryMemberCM__r?.Name.substring(0, c?.ARC_PrimaryMemberCM__r?.Name.length() <= 50 ? c?.ARC_PrimaryMemberCM__r?.Name.length() : 50));
            if(c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingStreet != null)  mapFieldNamesValue.put('cAddress1', (String) c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingStreet.substring(0, c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingStreet.length() <= 80 ? c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingStreet.length() : 80));
            if(c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingCity != null)  mapFieldNamesValue.put('cCity', (String) c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingCity.substring(0, c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingCity.length() <= 30 ? c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingCity.length() : 30));
            if(c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingState != null)  mapFieldNamesValue.put('cState', (String) c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingState.substring(0, c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingState.length() <= 2 ? c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingState.length() : 2));
            if(c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingPostalCode != null)  mapFieldNamesValue.put('cZip', (String) c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingPostalCode.substring(0, c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingPostalCode.length() <= 5 ? c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingPostalCode.length() : 5));
            mapFieldNamesValue.put('cRecipientCode', 'I');
            if(c?.ARC_Payment_To__c != null && c?.ARC_Payment_To__c== 'Member' && c?.ARC_TotalNetPaidAmount__c != null && c?.ARC_TotalNetPaidAmount__c>0 && checkClosing)mapFieldNamesValue.put('cDocumentType', '009');//EOB check
            else mapFieldNamesValue.put('cDocumentType', '008');//EOB only
        }
        mapFieldNamesValue.put('cClaimType', 'MED');
        // Add the Map values to XML_Claim variable
        XML_Claim += generateRecordLine('00', mapFieldNamesValue);
        // End recordType 00
        
        // Start recordType 01 - 21 nodes
        mapFieldNamesValue.clear();
        String contactRelationship;
        if(cont?.ARC_CensusMember__r?.vlocity_ins__IsPrimaryMember__c == true) contactRelationship = 'SELF';
        else contactRelationship = 'DEPENDENT';
        //cClaimSequence for Member or provider
        if(!isProvider)mapFieldNamesValue.put('cClaimSequence', '000001');//For Member
        else mapFieldNamesValue.put('cClaimSequence', '000002');//For Porvider
        if(c?.Name != null) mapFieldNamesValue.put('cClaimNumber', (String)c.Name.substring(0,c.Name.length() <= 50 ? c.Name.length() : 50));//5
        if(cont?.ARC_CensusMember__r?.ARC_Relationship__c == 'Primary'){
            if(cont?.Name != null)mapFieldNamesValue.put('cEnrolleeName', (String)cont.Name.substring(0,cont.Name.length() <= 80 ? cont.Name.length() : 80));//6
            if(cont?.FirstName != null)mapFieldNamesValue.put('cEnrolleeFirstName', (String)cont.FirstName.substring(0,cont.FirstName.length() <= 30 ? cont.FirstName.length() : 30));//7
            if(cont?.vlocity_ins__MiddleName__c != null)mapFieldNamesValue.put('cEnrolleeMiddleName', (String)cont.vlocity_ins__MiddleName__c.substring(0,cont.vlocity_ins__MiddleName__c.length() <= 30 ? cont.vlocity_ins__MiddleName__c.length() : 30));//7
            if(cont?.LastName != null)mapFieldNamesValue.put('cEnrolleeLastName', (String)cont.LastName.substring(0,cont.LastName.length() <= 30 ? cont.LastName.length() : 30));//7
        }
        else {
            if(cont?.ARC_CensusMember__r?.vlocity_ins__RelatedCensusMemberId__r?.Name != null)mapFieldNamesValue.put('cEnrolleeName', (String)cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.Name.substring(0,cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.Name.length() <= 80 ? cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.Name.length() : 80));//6
            if(cont?.ARC_CensusMember__r?.vlocity_ins__RelatedCensusMemberId__r?.vlocity_ins__FirstName__c != null)mapFieldNamesValue.put('cEnrolleeFirstName', (String)cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__FirstName__c.substring(0,cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__FirstName__c.length() <= 30 ? cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__FirstName__c.length() : 30));//7
            if(cont?.ARC_CensusMember__r?.vlocity_ins__RelatedCensusMemberId__r?.vlocity_ins__ContactId__r?.vlocity_ins__MiddleName__c != null)mapFieldNamesValue.put('cEnrolleeMiddleName', (String)cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.vlocity_ins__MiddleName__c.substring(0,cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.vlocity_ins__MiddleName__c.length() <= 30 ? cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.vlocity_ins__MiddleName__c.length() : 30));//7
            if(cont?.ARC_CensusMember__r?.vlocity_ins__RelatedCensusMemberId__r?.vlocity_ins__LastName__c != null)mapFieldNamesValue.put('cEnrolleeLastName', (String)cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__LastName__c.substring(0,cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__LastName__c.length() <= 30 ? cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__LastName__c.length() : 30));//7
        }
        if(c?.PolicyNumber?.Name != null)mapFieldNamesValue.put('cEnrolleePolicyNumber', String.valueOf(c.PolicyNumber.Name).substring(0,String.valueOf(c.PolicyNumber.Name).length() <= 20 ? String.valueOf(c.PolicyNumber.Name).length() : 20));//10
        if(cont?.Name != null)mapFieldNamesValue.put('cPatientName', (String) cont.Name.substring(0,cont.Name.length() <= 80 ? cont.Name.length() : 80));//14
        if(cont?.FirstName != null)mapFieldNamesValue.put('cPatientFirstName', (String) cont.FirstName.substring(0,cont.FirstName.length() <= 80 ? cont.FirstName.length() : 80));//14
        if(cont?.LastName != null)mapFieldNamesValue.put('cPatientLastName', (String) cont.LastName.substring(0,cont.LastName.length() <= 80 ? cont.LastName.length() : 80));//14
        if(c?.PolicyNumber?.Name != null) mapFieldNamesValue.put('cPatientAccountNumber', String.valueOf(c.PolicyNumber.Name).substring(0,String.valueOf(c.PolicyNumber.Name).length() <= 40 ? String.valueOf(c.PolicyNumber.Name).length() : 40));//16
        if(cont?.ARC_CensusMember__r?.ARC_Relationship__c != null)mapFieldNamesValue.put('cPatientRelationship', (String) contactRelationship.substring(0,contactRelationship.length() <= 20 ? contactRelationship.length() : 20));//18
        if(c?.ARC_OriginalReceivedDate__c != null)mapFieldNamesValue.put('cProcessedDate', (String)formatDate((Date)c.ARC_OriginalReceivedDate__c).substring(0,8));//20
        if(c?.ARC_DOSFrom__c != null) mapFieldNamesValue.put('cClaimYear', String.valueOf(c.ARC_DOSFrom__c.year()));//24
        mapFieldNamesValue.put('cGroupHierarchy1', 'UHSM');//26
        mapFieldNamesValue.put('cGroupName1', 'UNITED HEALTH SHARE MINISTRIES');//26.01
        mapFieldNamesValue.put('cGroupHierarchy2', String.valueOf('UNITED HEALTH SHARE').substring(0,15));//27 exeeds character limit.
        mapFieldNamesValue.put('cGroupHierarchy3', 'GENERAL LEDGER');
        if(c?.ARC_DOSFrom__c != null){
            String groupFive='FIRST HEALTH';
            if(c.ARC_DOSFrom__c.year()> Integer.valueOf(System.label.ARC_ZelisYearCompareGH5)) groupFive = 'MULTIPLAN';
            mapFieldNamesValue.put('cGroupHierarchy5', groupFive.substring(0,groupFive.length()<=15?groupFive.length():15));//TODO: Logic of DateOfService
        }
        mapFieldNamesValue.put('cGroupHierarchy6', 'UHSM'); 
        if(c.ARC_FlaggedAs__c != null && c?.ARC_FlaggedAs__c.contains('Letter')) mapFieldNamesValue.put('cGroupHierarchy7', 'LEGAL');

        
        String providerTaxId = (c?.ARC_Vendor__r?.vlocity_ins__TaxID__c != null) 
            ? removeDecimal(String.valueOf(c.ARC_Vendor__r.vlocity_ins__TaxID__c.replaceAll('-', ''))) 
            : '999999999';
    
        String nationalProviderId = c?.ARC_Vendor__r?.ARC_NationalProviderId__c != null 
            ? c.ARC_Vendor__r.ARC_NationalProviderId__c 
            : c?.ARC_Attending_Provider__r?.ARC_NationalProviderIdentifier__pc;
    
        System.debug(nationalProviderId);
        System.debug(nationalProviderId != '9999999999');
        if (nationalProviderId != null && nationalProviderId != '9999999999') {
            mapFieldNamesValue.put('cProviderTaxId', providerTaxId.substring(0, Math.min(providerTaxId.length(), 9)));
            mapFieldNamesValue.put('cNationalProviderID', nationalProviderId.substring(0, Math.min(nationalProviderId.length(), 10)));
        } else {
            mapFieldNamesValue.put('cProviderTaxId', '');
            mapFieldNamesValue.put('cNationalProviderID', '');
        }
    
        if(c?.ARC_Vendor__r?.Name!= null)mapFieldNamesValue.put('cProviderName', String.valueOf(c.ARC_Vendor__r.Name).substring(0,String.valueOf(c.ARC_Vendor__r.Name).length()<=80 ? String.valueOf(c.ARC_Vendor__r.Name).length():80));//42
        if(c?.Name != null)mapFieldNamesValue.put('cClaimRelationString',(String)c.Name.substring(0,c.Name.length()<=75 ? c.Name.length():75));//57
        if(cont?.Birthdate != null)mapFieldNamesValue.put('cPatientDateOfBirth', (String)formatDate((Date)cont.Birthdate).substring(0,8));//65
        if(c?.ARC_ClaimStatusCode__c != null)mapFieldNamesValue.put('cClaimStatusCode',(String)c.ARC_ClaimStatusCode__c);
        if(c?.ARC_FilingIndicatorCode__c != null)mapFieldNamesValue.put('cClaimFilingIndicatorCode',(String)c.ARC_FilingIndicatorCode__c);
        if(c?.ARC_MemberID__c != null)mapFieldNamesValue.put('cEnrolleeID',(String)c.ARC_MemberID__c);

        // Add the Map values to XML_Claim variable
        XML_Claim += generateRecordLine('01', mapFieldNamesValue);
        // End recordType 01

        // Start recordType 02 - 20 nodes
        if(listCCPD != null){
            for(ClaimCoveragePaymentDetail  ccpd: listCCPD){
                mapFieldNamesValue.clear();
                //cClaimSequence for Member or provider
                if(!isProvider)mapFieldNamesValue.put('cClaimSequence', '000001');//For Member
                else mapFieldNamesValue.put('cClaimSequence', '000002');//For Porvider
                if(c?.Name != null) mapFieldNamesValue.put('cClaimNumber', (String)c.Name.substring(0,c.Name.length() <= 50 ? c.Name.length() : 50));//4.5
                if(ccpd?.Name != null) mapFieldNamesValue.put('cServiceLineSequence', (String)ccpd.Name.substring(0,ccpd.Name.length() <= 5 ? ccpd.Name.length() : 5));//5
                if(ccpd?.Name != null) mapFieldNamesValue.put('cLineNumber', (String)ccpd.Name.substring(0,ccpd.Name.length() <= 3 ? ccpd.Name.length() : 3));//6
                //Populate Procedure Code for Professional and Revenue Code for Institutional Claims
                if(ccpd?.ARC_ProcedureCodeName__c != null) mapFieldNamesValue.put('cProcedureCode', (String)ccpd.ARC_ProcedureCodeName__c.substring(0,ccpd.ARC_ProcedureCodeName__c.length() <= 8 ? ccpd.ARC_ProcedureCodeName__c.length() : 8));//8
                if(ccpd?.ARC_ProcedureCode__r?.vlocity_ins__ShortDescription__c != null) mapFieldNamesValue.put('cDescription', (String)ccpd.ARC_ProcedureCode__r.vlocity_ins__ShortDescription__c.substring(0,ccpd.ARC_ProcedureCode__r.vlocity_ins__ShortDescription__c.length() <= 60 ? ccpd.ARC_ProcedureCode__r.vlocity_ins__ShortDescription__c.length() : 60));//11
                if(ccpd?.ARC_RevenueCode__c != null) mapFieldNamesValue.put('cRevenueCode', (String)ccpd.ARC_RevenueCode__c.substring(0,ccpd.ARC_RevenueCode__c.length() <= 8 ? ccpd.ARC_RevenueCode__c.length() : 8));//8
                
                //Print Date of Service depending on the Claim record type. 
                if(c?.RecordType?.Name != null && c.RecordType.Name == 'Professional'){
                    if(ccpd?.ARC_DateOfService__c!= null) mapFieldNamesValue.put('cServiceDateStart', (String)formatDate((Date)ccpd.ARC_DateOfService__c));//12
                    if(ccpd?.ARC_DateOfService__c != null) mapFieldNamesValue.put('cServiceDateEnd', (String)formatDate((Date)ccpd.ARC_DateOfService__c));//13
                }
                else{
                    if(ccpd?.ARC_DOSFrom__c!= null) mapFieldNamesValue.put('cServiceDateStart', (String)formatDate((Date)ccpd.ARC_DOSFrom__c));//12
                    if(ccpd?.ARC_DOSTo__c != null) mapFieldNamesValue.put('cServiceDateEnd', (String)formatDate((Date)ccpd.ARC_DOSTo__c));//13
                }
                if(ccpd?.ClaimedAmount != null) mapFieldNamesValue.put('cTotalCharge', decimalFormat(ccpd.ClaimedAmount).substring(0,decimalFormat(ccpd.ClaimedAmount).length() <= 15 ? decimalFormat(ccpd.ClaimedAmount).length() : 15));//14
                if(ccpd?.ARC_Discount__c != null) mapFieldNamesValue.put('cDiscount', String.valueOf(ccpd.ARC_Discount__c).substring(0,String.valueOf(ccpd.ARC_Discount__c).length() <= 15 ? String.valueOf(ccpd.ARC_Discount__c).length() : 15));//16
                if(ccpd?.ClaimedAmount != null) mapFieldNamesValue.put('cIneligible ', ccpd.Status.equalsIgnoreCase('denied') ? String.valueOf(ccpd.ClaimedAmount) : '0.00');//17
                if(ccpd?.ARC_Allowed__c != null) mapFieldNamesValue.put('cAllowed', String.valueOf(ccpd.ARC_Allowed__c).substring(0,String.valueOf(ccpd.ARC_Allowed__c).length() <= 15 ? String.valueOf(ccpd.ARC_Allowed__c).length() : 15));//19
                if(ccpd?.ARC_Deductible__c != null) mapFieldNamesValue.put('cDeductible', String.valueOf(ccpd.ARC_Deductible__c).substring(0,String.valueOf(ccpd.ARC_Deductible__c).length() <= 15 ? String.valueOf(ccpd.ARC_Deductible__c).length() : 15));//23
                if(ccpd?.ARC_Copay__c != null) mapFieldNamesValue.put('cCoPay', String.valueOf(ccpd.ARC_Copay__c).substring(0,String.valueOf(ccpd.ARC_Copay__c).length() <= 15 ? String.valueOf(ccpd.ARC_Copay__c).length() : 15));//24
                if(ccpd?.ARC_CoInsurance__c != null) mapFieldNamesValue.put('cCoInsurance', String.valueOf(ccpd.ARC_CoInsurance__c).substring(0,String.valueOf(ccpd.ARC_CoInsurance__c).length() <= 15 ? String.valueOf(ccpd.ARC_CoInsurance__c).length() : 15));//25
                if(ccpd?.ARC_NetPaid__c != null) mapFieldNamesValue.put('cPayment', String.valueOf(ccpd.ARC_NetPaid__c).substring(0,String.valueOf(ccpd.ARC_NetPaid__c).length() <= 15 ? String.valueOf(ccpd.ARC_NetPaid__c).length() : 15));//29
                if(ccpd?.ARC_MBRLiability__c != null) mapFieldNamesValue.put('cPatientResponsibility', String.valueOf(ccpd.ARC_MBRLiability__c).substring(0,String.valueOf(ccpd.ARC_MBRLiability__c).length() <= 15 ? String.valueOf(ccpd.ARC_MBRLiability__c).length() : 15));//30
                if(ccpd?.ARC_Pre_Existing_Condition__c != null) mapFieldNamesValue.put('cOtherAmount2', String.valueOf(ccpd.ARC_Pre_Existing_Condition__c).substring(0,String.valueOf(ccpd.ARC_Pre_Existing_Condition__c).length() <= 15 ? String.valueOf(ccpd.ARC_Pre_Existing_Condition__c).length() : 15));//32
                if(ccpd?.ARC_Tobacco__c != null) mapFieldNamesValue.put('cOtherAmount3', String.valueOf(ccpd.ARC_Tobacco__c).substring(0,String.valueOf(ccpd.ARC_Tobacco__c).length() <= 15 ? String.valueOf(ccpd.ARC_Tobacco__c).length() : 15));//31
                if(ccpd?.Name != null) mapFieldNamesValue.put('cClaimRelationString', (String)c.Name.substring(0,c.Name.length() <= 75 ? c.Name.length() : 75));//46
                Integer cNotesCodeType = 1;
                if(ccpd?.Claim_Reason_Codes__r != null){
                    for(ARC_ClaimReasonCode__c cReasonCode : ccpd.Claim_Reason_Codes__r){
                        if(cReasonCode?.ARC_CodeNameText__c != null) mapFieldNamesValue.put('cNotesCode'+cNotesCodeType+'Type', (String)cReasonCode.ARC_CodeNameText__c.substring(0,cReasonCode.ARC_CodeNameText__c.length() <= 10 ? cReasonCode.ARC_CodeNameText__c.length() : 10));//61,62,63,64

                        if(cReasonCode?.ARC_ReasonCode__r?.ARC_WPCClaimEditCode__c != null) mapFieldNamesValue.put('cSvcAdjustmentReasonCode', (String)cReasonCode.ARC_ReasonCode__r?.ARC_WPCClaimEditCode__c.substring(0,cReasonCode.ARC_ReasonCode__r?.ARC_WPCClaimEditCode__c.length() <= 5 ? cReasonCode.ARC_ReasonCode__r?.ARC_WPCClaimEditCode__c.length() : 5));//70 CARC
                        if(cReasonCode?.ARC_ReasonCode__r?.ARC_WPCRemarkCode__c != null) mapFieldNamesValue.put('cSvcRARC', (String)cReasonCode.ARC_ReasonCode__r?.ARC_WPCRemarkCode__c.substring(0,cReasonCode.ARC_ReasonCode__r?.ARC_WPCRemarkCode__c.length() <= 5 ? cReasonCode.ARC_ReasonCode__r?.ARC_WPCRemarkCode__c.length() : 5));//71 RARC
                        cNotesCodeType++;
                    }
                }
                if(ccpd?.AdjustedAmount != null) mapFieldNamesValue.put('cSvcAdjustmentamount', String.valueOf(ccpd.AdjustedAmount).substring(0,String.valueOf(ccpd.AdjustedAmount).length() <= 15 ? String.valueOf(ccpd.AdjustedAmount).length() : 15));//68
                // Add the Map values to XML_Claim variable
                XML_Claim += generateRecordLine('02', mapFieldNamesValue);
            }
        }
        // End recordType 02

        // Start recordType 03 - 12 nodes
        mapFieldNamesValue.clear();
        //cClaimSequence for Member or provider
        if(!isProvider)mapFieldNamesValue.put('cClaimSequence', '000001');//For Member
        else mapFieldNamesValue.put('cClaimSequence', '000002');//For Provider
        if(c?.ARC_ClaimTotalAmount__c != null)mapFieldNamesValue.put('cTotalCharge', decimalFormat(c.ARC_ClaimTotalAmount__c).substring(0,decimalFormat(c.ARC_ClaimTotalAmount__c).length() <= 15 ? decimalFormat(c.ARC_ClaimTotalAmount__c).length():15));//5
        if(c?.ARC_TotalDiscountAmount__c!= null)mapFieldNamesValue.put('cDiscount', decimalFormat(c.ARC_TotalDiscountAmount__c).substring(0,decimalFormat(c.ARC_TotalDiscountAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalDiscountAmount__c).length():15));//6
        if(c?.ARC_TotalIneligibleAmount__c != null)mapFieldNamesValue.put('cIneligible', decimalFormat(c.ARC_TotalIneligibleAmount__c).substring(0,decimalFormat(c.ARC_TotalIneligibleAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalIneligibleAmount__c).length():15));//7
        if(c?.ARC_TotalAllowedAmount__c != null) mapFieldNamesValue.put('cAllowed', decimalFormat(c.ARC_TotalAllowedAmount__c).substring(0,decimalFormat(c.ARC_TotalAllowedAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalAllowedAmount__c).length():15));//8
        if(c?.ARC_TotalDeductibleAmount__c!= null) mapFieldNamesValue.put('cDeductible', decimalFormat(c.ARC_TotalDeductibleAmount__c).substring(0,decimalFormat(c.ARC_TotalDeductibleAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalDeductibleAmount__c).length():15));//9
        if(c?.ARC_TotalCopayAmount__c != null) mapFieldNamesValue.put('cCopay', decimalFormat(c.ARC_TotalCopayAmount__c).substring(0,decimalFormat(c.ARC_TotalCopayAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalCopayAmount__c).length():15));//10
        if(c?.ARC_TotalCoinsuranceAmount__c != null) mapFieldNamesValue.put('cCoinsurance', decimalFormat(c.ARC_TotalCoinsuranceAmount__c).substring(0,decimalFormat(c.ARC_TotalCoinsuranceAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalCoinsuranceAmount__c).length():15));//11
        if(c?.ARC_TotalNetPaidAmount__c!= null)mapFieldNamesValue.put('cPayment', decimalFormat(c.ARC_TotalNetPaidAmount__c).substring(0,decimalFormat(c.ARC_TotalNetPaidAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalNetPaidAmount__c).length():15));//12
        if(c?.ARC_TotalPatientResponsibilityAmount__c!= null)mapFieldNamesValue.put('cPatientResponsibility', decimalFormat(c.ARC_TotalPatientResponsibilityAmount__c).substring(0,decimalFormat(c.ARC_TotalPatientResponsibilityAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalPatientResponsibilityAmount__c).length():15));//13
        if(c?.ARC_TotalPreviouslyPaidAmount__c != null) mapFieldNamesValue.put('cOtherAmount1', decimalFormat(c.ARC_TotalPreviouslyPaidAmount__c).substring(0,decimalFormat(c.ARC_TotalPreviouslyPaidAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalPreviouslyPaidAmount__c).length():15));//14
        if(c?.ARC_Total_PreExistingConditions__c!= null)mapFieldNamesValue.put('cOtherAmount2', decimalFormat(c.ARC_Total_PreExistingConditions__c).substring(0,decimalFormat(c.ARC_Total_PreExistingConditions__c).length() <= 15 ? decimalFormat(c.ARC_Total_PreExistingConditions__c).length():15));//15
        if(c?.ARC_TotalTobacco__c != null) mapFieldNamesValue.put('cOtherAmount3', decimalFormat(c.ARC_TotalTobacco__c).substring(0,decimalFormat(c.ARC_TotalTobacco__c).length() <= 15 ? decimalFormat(c.ARC_TotalTobacco__c).length():15));//16
        if(c?.ARC_TotalMBRLiabilityAmount__c != null) mapFieldNamesValue.put('cOtherAmount4', decimalFormat(c.ARC_TotalMBRLiabilityAmount__c).substring(0,decimalFormat(c.ARC_TotalMBRLiabilityAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalMBRLiabilityAmount__c).length():15));//17
        if(c?.Name != null)mapFieldNamesValue.put('cClaimRelationString',(String)c.Name.substring(0,c.Name.length()<=75 ? c.Name.length():75));//17
        // Add the Map values to XML_Claim variable
        XML_Claim += generateRecordLine('03', mapFieldNamesValue);
        // End recordType 03

        // Start recordType 04 - 1 node
        mapFieldNamesValue.clear();
        if(c?.Name != null) mapFieldNamesValue.put('cClaimNumber', (String)c.Name.substring(0,c.Name.length() <= 50 ? c.Name.length() : 50));//5
        if(c?.Name != null) mapFieldNamesValue.put('cClaimRelationString', (String)c.Name.substring(0,c.Name.length() <= 75 ? c.Name.length() : 75));//3.5
        mapFieldNamesValue.put('cDescription','NA');//8
        // Add the Map values to XML_Claim variable
        XML_Claim += generateRecordLine('04', mapFieldNamesValue);
        // End recordType 04        

        // Start recordType 06 - 05 bides
        mapFieldNamesValue.clear();
        //System.debug('TotalNet: '+ c?.ARC_TotalNetPaidAmount__c);
        //System.debug('Payto: '+  c?.ARC_Payment_To__c);
        if(checkClosing){
            if(c?.ARC_TotalNetPaidAmount__c != null && c?.ARC_TotalNetPaidAmount__c != 0.00 && ((isProvider && c?.ARC_Payment_To__c== 'Provider') || (!isProvider && c?.ARC_Payment_To__c== 'Member'))){
                //Generate cPayeeName.
                String cPayeeName = '';
                if(c?.ARC_Payment_To__c== 'Provider' && c.ARC_Vendor__r.Name != null) cPayeeName = (String)c.ARC_Vendor__r.Name.substring(0, Math.min(c.ARC_Vendor__r.Name.length(), 80));
                else if(cont?.ARC_CensusMember__r?.ARC_Relationship__c == 'Primary' && cont?.Name != null) cPayeeName = (String)cont.Name.substring(0, Math.min(cont.Name.length(), 80));
                else if(cont?.ARC_CensusMember__r?.vlocity_ins__RelatedCensusMemberId__r?.Name != null) cPayeeName = (String)cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.Name.substring(0, Math.min(cont.ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.Name.length(), 80));
                
                String numberToString = decimalToWords(c.ARC_TotalNetPaidAmount__c );
                mapFieldNamesValue.put('cTextAmount', numberToString.substring(0,numberToString.length()<=150 ? numberToString.length():150));//13
                mapFieldNamesValue.put('cCheckAmount', decimalFormat(c.ARC_TotalNetPaidAmount__c).substring(0,decimalFormat(c.ARC_TotalNetPaidAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalNetPaidAmount__c).length():15));//17
                mapFieldNamesValue.put('cPayeeName', cPayeeName);
                if(String.isNotBlank(c.ARC_CheckNumber__c))mapFieldNamesValue.put('cCheckNumber',formatCheckNumber(Decimal.valueOf(c.ARC_CheckNumber__c)).substring(0,formatCheckNumber(Decimal.valueOf(c.ARC_CheckNumber__c)).length() <= 16 ? formatCheckNumber(Decimal.valueOf(c.ARC_CheckNumber__c)).length():16));
                mapFieldNamesValue.put('cCheckDate', (String)(formatDate(Date.today())));
                if(c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingStreet != null)  mapFieldNamesValue.put('cPayeeAddress1', (String) c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingStreet.substring(0, c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingStreet.length() <= 40 ? c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account?.BillingStreet.length() : 40)); //26
                // Add the Map values to XML_Claim variable
                XML_Claim += generateRecordLine('06', mapFieldNamesValue);
            }
        }
        // End recordType 06

        // Start recordType 17 - 7 nodes
        mapFieldNamesValue.clear();
        if(c?.ARC_ClaimTotalAmount__c != null) mapFieldNamesValue.put('cTotalCharge', decimalFormat(c.ARC_ClaimTotalAmount__c).substring(0,decimalFormat(c.ARC_ClaimTotalAmount__c).length() <= 15 ? decimalFormat(c.ARC_ClaimTotalAmount__c).length():15));//5
        if(c?.ARC_TotalDiscountAmount__c!= null)mapFieldNamesValue.put('cDiscount', decimalFormat(c.ARC_TotalDiscountAmount__c).substring(0,decimalFormat(c.ARC_TotalDiscountAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalDiscountAmount__c).length():15));//6
        if(c?.ARC_TotalIneligibleAmount__c != null)mapFieldNamesValue.put('cIneligible', decimalFormat(c.ARC_TotalIneligibleAmount__c).substring(0,decimalFormat(c.ARC_TotalIneligibleAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalIneligibleAmount__c).length():15));//7
        if(c?.ARC_TotalDeductibleAmount__c!= null) mapFieldNamesValue.put('cDeductible', decimalFormat(c.ARC_TotalDeductibleAmount__c).substring(0,decimalFormat(c.ARC_TotalDeductibleAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalDeductibleAmount__c).length():15));//10
        if(c?.ARC_TotalCopayAmount__c != null) mapFieldNamesValue.put('cCopay', decimalFormat(c.ARC_TotalCopayAmount__c).substring(0,decimalFormat(c.ARC_TotalCopayAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalCopayAmount__c).length():15));//11
        if(c?.ARC_TotalCoinsuranceAmount__c != null) mapFieldNamesValue.put('cCoinsurance', decimalFormat(c.ARC_TotalCoinsuranceAmount__c).substring(0,decimalFormat(c.ARC_TotalCoinsuranceAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalCoinsuranceAmount__c).length():15));//12
        if(c?.ARC_TotalPreviouslyPaidAmount__c != null) mapFieldNamesValue.put('cOtherAmount1', decimalFormat(c.ARC_TotalPreviouslyPaidAmount__c).substring(0,decimalFormat(c.ARC_TotalPreviouslyPaidAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalPreviouslyPaidAmount__c).length():15));//13
        if(c?.ARC_Total_PreExistingConditions__c != null) mapFieldNamesValue.put('cOtherAmount2', decimalFormat(c.ARC_Total_PreExistingConditions__c).substring(0,decimalFormat(c.ARC_Total_PreExistingConditions__c).length() <= 15 ? decimalFormat(c.ARC_Total_PreExistingConditions__c).length():15));//14
        if(c?.ARC_TotalTobacco__c != null) mapFieldNamesValue.put('cOtherAmount3', decimalFormat(c.ARC_TotalTobacco__c).substring(0,decimalFormat(c.ARC_TotalTobacco__c).length() <= 15 ? decimalFormat(c.ARC_TotalTobacco__c).length():15));//15
        if(c?.ARC_TotalMBRLiabilityAmount__c != null) mapFieldNamesValue.put('cOtherAmount4', decimalFormat(c.ARC_TotalMBRLiabilityAmount__c).substring(0,decimalFormat(c.ARC_TotalMBRLiabilityAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalMBRLiabilityAmount__c).length():15));//16
        if(c?.ARC_TotalNetPaidAmount__c!= null)mapFieldNamesValue.put('cPayment', decimalFormat(c.ARC_TotalNetPaidAmount__c).substring(0,decimalFormat(c.ARC_TotalNetPaidAmount__c).length() <= 15 ? decimalFormat(c.ARC_TotalNetPaidAmount__c).length():15));//16
        // Add the Map values to XML_Claim variable
        XML_Claim += generateRecordLine('17', mapFieldNamesValue);
        // End recordType 17

        // Start recordType 20 - 2 nodes
        mapFieldNamesValue.clear();
        if(listCCPD != null){
            List<String> procedureCodeList= new List<String>();
            for(ClaimCoveragePaymentDetail  ccpd: listCCPD){
                //Populate Procedure Codes for Professionals and Revenue Code for Institutional Claims
                if(c?.RecordType?.Name != null && c.RecordType.Name == 'Professional'){                   
                    if(ccpd?.Arc_ProcedureCodeName__c != null && !procedureCodeList.contains(ccpd.Arc_ProcedureCodeName__c)){
                        mapFieldNamesValue.put('cProcedureCode', (String)ccpd.Arc_ProcedureCodeName__c.substring(0,ccpd.Arc_ProcedureCodeName__c.length() <= 10 ? ccpd.Arc_ProcedureCodeName__c.length() : 10));//4
                        if(ccpd?.Arc_ProcedureCode__r?.vlocity_ins__ShortDescription__c != null) mapFieldNamesValue.put('cProcedureDescription', (String)ccpd.Arc_ProcedureCode__r.vlocity_ins__ShortDescription__c.substring(0,ccpd.Arc_ProcedureCode__r.vlocity_ins__ShortDescription__c.length() <= 1000 ? ccpd.Arc_ProcedureCode__r.vlocity_ins__ShortDescription__c.length() : 1000));//5
                        procedureCodeList.add(ccpd.Arc_ProcedureCodeName__c);
                        // Add the Map values to XML_Claim variable
                        XML_Claim += generateRecordLine('20', mapFieldNamesValue);
                    }
                }
                else {
                    if(ccpd?.ARC_RevenueCode__c != null && !procedureCodeList.contains(ccpd.ARC_RevenueCode__c)) {
                        mapFieldNamesValue.put('cProcedureCode', (String)ccpd.ARC_RevenueCode__c.substring(0,ccpd.ARC_RevenueCode__c.length() <= 10 ? ccpd.ARC_RevenueCode__c.length() : 10));//4
                        procedureCodeList.add(ccpd.ARC_RevenueCode__c);
                        // Add the Map values to XML_Claim variable
                        XML_Claim += generateRecordLine('20', mapFieldNamesValue);
                    }
                }
            }
        }
        // End recordType 20

        //Iterate over Claim Line Items
        // Start recordType 21 - 2 nodes
        if(listCCPD != null){
            List<String> remarkCodeList= new List<String>();
            for(ClaimCoveragePaymentDetail  ccpd: listCCPD){
                if(ccpd?.Claim_Reason_Codes__r != null){
                    mapFieldNamesValue.clear();
                    for(ARC_ClaimReasonCode__c cReasonCode : ccpd.Claim_Reason_Codes__r){
                        if(cReasonCode?.ARC_CodeNameText__c != null && !remarkCodeList.contains(cReasonCode.ARC_CodeNameText__c)) {
                            mapFieldNamesValue.put('cRemarkCode',(String)cReasonCode.ARC_CodeNameText__c.substring(0,cReasonCode.ARC_CodeNameText__c.length() <= 10 ? cReasonCode.ARC_CodeNameText__c.length() : 10));//4
                            if(cReasonCode?.ARC_CodeDescription__c!= null) mapFieldNamesValue.put('cRemarkDescription',(String)cReasonCode.ARC_CodeDescription__c.substring(0,cReasonCode.ARC_CodeDescription__c.length() <= 1200 ? cReasonCode.ARC_CodeDescription__c.length() : 1200));//5
                            //Include cRmarkCodeDescription
                            remarkCodeList.add(cReasonCode.ARC_CodeNameText__c);
                            // Add the Map values to XML_Claim variable
                            XML_Claim += generateRecordLine('21', mapFieldNamesValue);
                        }
                    }
                }
            }
        }
        // End recordType 21

        
        // Start recordType 32 - 6 nodes
        if(listCCPD != null){
            
            for(ClaimCoveragePaymentDetail  ccpd: listCCPD){ // For each SMB Item
                //CONTRACTUAL OBLIGACION CODES OR DENIED CODES
                for (ARC_ClaimReasonCode__c reason_code : ccpd.Claim_Reason_Codes__r) { // For each reason code

                    String cAdjustmentGroupCode = reason_code.ARC_ReasonCode__r?.ARC_WPCInfoCode__c; //Letters -> CO,PR,etc
                    String cAdjustmentReasonCode = reason_code.ARC_ReasonCode__r?.ARC_WPCClaimEditCode__c; //Number 1,2,3 ... 131
                    String cAdjustmentReasonStatus = reason_code.ARC_ReasonCode__r?.ARC_Status__c; //Number 1,2,3 ... 131

                    System.debug(cAdjustmentGroupCode +' '+ cAdjustmentReasonCode +' '+ cAdjustmentReasonStatus);

                    if(cAdjustmentGroupCode != null &&  ((cAdjustmentReasonStatus.equalsIgnoreCase('informational')  && cAdjustmentGroupCode.equalsIgnoreCase('CO')) || cAdjustmentReasonStatus.equalsIgnoreCase('denied'))){
                        mapFieldNamesValue.clear(); // Clear map with values for each reason code

                        if(isProvider == false){
                            mapFieldNamesValue.put('cClaimSequence', '000001');
                        } else if (isProvider == true) {
                            mapFieldNamesValue.put('cClaimSequence', '000002');
                        }
    
                        if(c?.Name != null){
                            String cClaimNumber = c.Name.substring(0, Math.min(50, c.Name.length())); // Gets the minimum between 50 and the length of the string
                            mapFieldNamesValue.put('cClaimNumber', cClaimNumber);
                        }
                        
                        if(ccpd?.Name != null) {
                            String cLineNumber = ccpd.Name.substring(0, Math.min(3, ccpd.Name.length())); // Gets the minimum between 3 and the length of the string
                            mapFieldNamesValue.put('cLineNumber', cLineNumber);
                        }
    
                        if(ccpd?.Name != null){
                            String cClaimRelationString = c.Name.substring(0, Math.min(75, c.Name.length())); // Gets the minimum between 50 and the length of the string
                            mapFieldNamesValue.put('cClaimRelationString', cClaimRelationString);
                        }
                        
                        //NOTA: Revisar para el caso de los adjustments y testear que la logica este correcta
                        if(ccpd?.ClaimedAmount != null && ccpd.ARC_Allowed__c != null && ccpd.Status.equalsIgnoreCase('paid') || ccpd.Status.equalsIgnoreCase('adjustment')){
                            mapFieldNamesValue.put('cAdjustmentAmount', String.valueOf(ccpd.ClaimedAmount - ccpd.ARC_Allowed__c));
                        } else if (ccpd?.ClaimedAmount != null && ccpd.Status.equalsIgnoreCase('denied')){
                            mapFieldNamesValue.put('cAdjustmentAmount', String.valueOf(ccpd.ClaimedAmount));
                        }

                        mapFieldNamesValue.put('cAdjustmentGroupCode', cAdjustmentGroupCode);
                        if (cAdjustmentReasonCode != null) {
                            mapFieldNamesValue.put('cAdjustmentReasonCode', cAdjustmentReasonCode);
                        }

                        // Add the Map values to XML_Claim variable
                        XML_Claim += generateRecordLine('32', mapFieldNamesValue);
                        
                        // PATIENT RESPONSABILITY CODES
                        if(ccpd?.ClaimedAmount != null && ccpd.ARC_Allowed__c != null && ccpd.Status.equalsIgnoreCase('paid') || ccpd.Status.equalsIgnoreCase('adjustment')){
                            List<String> hardcoded_field_columns = new List<String>{'ARC_Deductible__c','ARC_Coinsurance__c','ARC_Copay__c','ARC_MBRLiability__c'};
                            for (String field_name : hardcoded_field_columns) {
                                Decimal field_value_amount = (Decimal)ccpd.get(field_name);

                                if (field_value_amount != null && field_value_amount > 0) {
                                    // Clear map with values for each reason code
                                    mapFieldNamesValue.clear();

                                    if(isProvider == false){
                                        mapFieldNamesValue.put('cClaimSequence', '000001');
                                    } else if (isProvider == true) {
                                        mapFieldNamesValue.put('cClaimSequence', '000002');
                                    }
                
                                    if(c?.Name != null){
                                        // Gets the minimum between 50 and the length of the string
                                        String cClaimNumber = c.Name.substring(0, Math.min(50, c.Name.length())); 
                                        mapFieldNamesValue.put('cClaimNumber', cClaimNumber);
                                    }
                                    
                                    if(ccpd?.Name != null) {
                                        // Gets the minimum between 3 and the length of the string
                                        String cLineNumber = ccpd.Name.substring(0, Math.min(3, ccpd.Name.length()));
                                        mapFieldNamesValue.put('cLineNumber', cLineNumber);
                                    }
                
                                    if(ccpd?.Name != null){
                                        // Gets the minimum between 50 and the length of the string
                                        String cClaimRelationString = c.Name.substring(0, Math.min(75, c.Name.length())); 
                                        mapFieldNamesValue.put('cClaimRelationString', cClaimRelationString);
                                    } 
                                    
                                    //NOTA: Revisar para el caso de los adjustments y testear que la logica este correcta
                                    if(ccpd?.ClaimedAmount != null && ccpd.ARC_Allowed__c != null){
                                        mapFieldNamesValue.put('cAdjustmentAmount', String.valueOf(field_value_amount));
                                    }
                
                                    mapFieldNamesValue.put('cAdjustmentGroupCode', 'PR'); // PR stands for Patient Responsability
                                    mapFieldNamesValue.put('cAdjustmentReasonCode', String.valueOf(hardcoded_field_columns.indexOf(field_name)+1));

                                    // Add the Map values to XML_Claim variable
                                    XML_Claim += generateRecordLine('32', mapFieldNamesValue);
                                }
                            }
                        }
                        break;
                    }
                }
                

                if(ccpd?.Claim_Reason_Codes__r != null && ccpd.Claim_Reason_Codes__r.size() > 0){
                    String lineCARC = ccpd.Claim_Reason_Codes__r[0].ARC_ReasonCode__r?.ARC_WPCClaimEditCode__c;
                    if (lineCARC != null) mapFieldNamesValue.put('cAdjustmentReasonCode', lineCARC.substring(0,lineCARC.length() <= 10 ? lineCARC.length() : 10)); // CARC
                    String lineRARC = ccpd.Claim_Reason_Codes__r[0].ARC_ReasonCode__r?.ARC_WPCRemarkCode__c;
                    if (lineRARC != null) mapFieldNamesValue.put('cSvcRARC', lineRARC.substring(0,lineRARC.length() <= 5 ? lineRARC.length() : 5)); // RARC
                }
            }
        }
        // End recordType 32

        // Close document
        XML_Claim += '</document>\n';
        return XML_Claim;
    }

    public static String generateRecordLine(String recordType, Map<String, String> mapFieldNamesValue) {
        // Start record
        String XML_Record = '<record recordType="' + recordType + '">\n';
        // Populate all fields
        for ( String fieldName : mapFieldNamesValue.keySet() ) {
            XML_Record += '<field fieldName="' + fieldName + '">' + mapFieldNamesValue.get(fieldName).escapeXml() + '</field>\n';
        }
        // Close record
        XML_Record += '</record>\n'; 
        return XML_Record;
    }

    public static String formatDate(Date d){
        if ( d != null ) {
            String day = String.valueOf(d.day());
            if ( day.length() == 1 ) {
                day = '0' + day;
            }
            String month = String.valueOf(d.month());
            if ( month.length() == 1 ) {
                month = '0' + month;
            }
            return d.year() + month + day;
        }
        return '';
    }

    public static String decimalFormat(Decimal d){
        return String.valueOf(d.setScale(2));
    }

    public static String removeDecimal (String s){
        String res = s;
        if(res.endsWith('.0')) res =res.replace('.0','');
        return res;
    }

    public static String decimalToWords(Decimal d){
        String result;
        String numberToString =ARC_NumberToWord.english_number(Integer.valueOf(d)).toUpperCase();
        String decimalNumber = String.valueOf(d.setScale(2)).substringAfter('.');
        String decimalToString =ARC_NumberToWord.english_number(Integer.valueOf(decimalNumber)).toUpperCase();
        if(decimalNumber != '00') return result = numberToString+' DOLLARS AND '+ decimalToString+' CENTS';
        else return result = numberToString+' DOLLARS';
    }

    public static String formatCheckNumber(Decimal d){
        //System.debug('Input: '+d);
        String result = String.valueOf(d).substringBefore('.');
        //System.debug('Output: '+result);
        return result;
    }
}