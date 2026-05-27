public with sharing class ARC_ClaimTriggersHandler {
    public static void sumNetPaidToCheckrun(List<Claim> clmListNew, List<Claim> clmListOld) {
        try {
            Map<Id, Id> oldClmCheckRun = new Map<Id, Id>();
            //Map of checkRuns to Update
            Map<Id, Decimal> checkRunAmountMapUpdate = new Map<Id, Decimal>();
    
            for (Claim oldC : clmListOld) if (oldC.ARC_CheckRun__c != null)oldClmCheckRun.put(oldC.Id, oldC.ARC_CheckRun__c);
    
            for (Claim newC : clmListNew) {
                if (oldClmCheckRun.get(newC.Id) == null && newC.ARC_CheckRun__c != null) {
                    checkRunAmountMapUpdate.put(newC.ARC_CheckRun__c,checkRunAmountMapUpdate.get(newC.ARC_CheckRun__c)!= null? checkRunAmountMapUpdate.get(newC.ARC_CheckRun__c) + newC.ARC_TotalNetPaidAmount__c:newC.ARC_TotalNetPaidAmount__c);
                }
                else if (oldClmCheckRun.get(newC.Id) != null && newC.ARC_CheckRun__c == null) {
                    checkRunAmountMapUpdate.put(oldClmCheckRun.get(newC.Id),checkRunAmountMapUpdate.get(oldClmCheckRun.get(newC.Id))!= null? checkRunAmountMapUpdate.get(oldClmCheckRun.get(newC.Id)) - newC.ARC_TotalNetPaidAmount__c:(newC.ARC_TotalNetPaidAmount__c*-1));
                }
                else if (oldClmCheckRun.get(newC.Id) != null && newC.ARC_CheckRun__c != null && oldClmCheckRun.get(newC.Id) != newC.ARC_CheckRun__c) {
                    checkRunAmountMapUpdate.put(oldClmCheckRun.get(newC.Id),checkRunAmountMapUpdate.get(oldClmCheckRun.get(newC.Id))!= null? checkRunAmountMapUpdate.get(oldClmCheckRun.get(newC.Id)) - newC.ARC_TotalNetPaidAmount__c:(newC.ARC_TotalNetPaidAmount__c*-1));
                    checkRunAmountMapUpdate.put(newC.ARC_CheckRun__c,checkRunAmountMapUpdate.get(newC.ARC_CheckRun__c)!= null? checkRunAmountMapUpdate.get(newC.ARC_CheckRun__c) + newC.ARC_TotalNetPaidAmount__c:newC.ARC_TotalNetPaidAmount__c);
                }
            }
            if (!checkRunAmountMapUpdate.isEmpty()) {
                List<ARC_CheckRun__c> checkruns = [SELECT Id, ARC_TotalPaid__c FROM ARC_CheckRun__c WHERE Id IN: checkRunAmountMapUpdate.keySet() LIMIT 5000];
                if (checkruns.size() > 0) {
                    for (ARC_CheckRun__c chkRun: checkruns)chkRun.ARC_TotalPaid__c = chkRun.ARC_TotalPaid__c + checkRunAmountMapUpdate.get(chkRun.Id);
                    update checkruns;
                }
            }
        } catch (Exception e) {
            System.debug('Exception in ARC_ClaimTriggers.sumNetPaidToCheckrun: '+e.getMessage());
        }
    }

    public static void preventCloseIfunpaidItems (Map<Id, Claim> oldClmList, Map<Id, Claim> newClmList) {
        List<Claim> clms = new List<Claim>();
        Set<Id> clmIds = new Set<Id>();

        for (Id newClmId : newClmList.keySet()) {
            Claim nClaim = newClmList.get(newClmId);
            Claim oClaim = oldClmList.get(newClmId);

            if (oClaim.Status != nClaim.Status && (nClaim.Status == 'AA Approved' || nClaim.Status == 'Manual Approved' || nClaim.Status == 'AA Denied' || nClaim.Status == 'Manual Denied')) {
                clms.add(nClaim);
                clmIds.add(nClaim.Id);
            }
        }

        if (clms.size() > 0) {
            //Check If the CLaim Line Items are closed.
            Set<Id> failedClms = new Set<Id>();
            Map<Id, Boolean> failClaimMap = new Map<Id, Boolean>();
            Map<Id, Boolean> claimsSMBDenied = new Map<Id, Boolean>();
            //Get the claim line items
            List<ClaimCOveragePaymentDetail> clis = [SELECT Id, Name, ARC_Claim__c, Status, ClaimPaymentSummaryId FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c IN :clmIds];
             if (clis.size() > 0) {
                for (ClaimCoveragePaymentDetail line : clis) {
                    if (failClaimMap.get(line.ARC_Claim__c) == null) {
                        //Claim Line Items are closed if Status = Denied or Status = 'Paid'
                        if (line.Status == 'Denied' || line.Status == 'Paid') {
                            if (line.Status == 'Denied') {
                                if (claimsSMBDenied.get(line.ARC_Claim__c) != null) claimsSMBDenied.put(line.ARC_Claim__c, (claimsSMBDenied.get(line.ARC_Claim__c) && true));
                                else claimsSMBDenied.put(line.ARC_Claim__c, true);
                            }
                            else {
                                if (claimsSMBDenied.get(line.ARC_Claim__c) != null) claimsSMBDenied.put(line.ARC_Claim__c, (claimsSMBDenied.get(line.ARC_Claim__c) && false));
                                else claimsSMBDenied.put(line.ARC_Claim__c, false);
                            }
                        }
                        else {
                            System.debug('failClaim');
                            failClaimMap.put(line.ARC_Claim__c,true);
                        }
                    }
                }
                Map<Id, Claim> clmsWithRelatedFields = new Map<Id, Claim> ([
                    SELECT Id, ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingStreet,
                        ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingPostalCode, ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingState,
                        ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingCity, ARC_Payment_To__c, ARC_ProviderXMLFieldsCompleted__c, ARC_MemberXMLFieldsCompleted__c,
                        Status, ARC_AreItemsClosed__c, ARC_VRHelper__c, ARC_AllSMBItemsDenied__c, ARC_PayToStreet__c, ARC_PayToCity__c, ARC_PayTo_State__c, ARC_PayTo_ZipCode__c
                    FROM Claim
                    WHERE Id IN :clmIds LIMIT 1000
                ]);
    
                for (Claim clm : clms) {

                    //Check if the Mandatory Fields for XML were completed
                    if (clm.ARC_Payment_To__c == 'Provider') {
                        clm.ARC_ProviderXMLFieldsCompleted__c=XMLFiledsCheckProvider(clm);
                        clm.ARC_MemberXMLFieldsCompleted__c = XMLFiledsCheckMember(clmsWithRelatedFields.get(clm.Id));

                    }
                    else clm.ARC_MemberXMLFieldsCompleted__c = XMLFiledsCheckMember(clmsWithRelatedFields.get(clm.Id));
                    System.debug('clm.ARC_MemberXMLFieldsCompleted__c'+clm.ARC_MemberXMLFieldsCompleted__c);
                
                    //Check if the Claim Line Items are Closed. 
                    if (failClaimMap.get(clm.Id) != null && failClaimMap.get(clm.Id) == true) clm.ARC_AreItemsClosed__c=false;                 
                    else clm.ARC_AreItemsClosed__c=true;
    
                    //If the Claim Line Items are Open or there is missing information on Member or Provider, roll back the status of the Claim.
                    if (!clm.ARC_AreItemsClosed__c || !clm.ARC_ProviderXMLFieldsCompleted__c || !clm.ARC_MemberXMLFieldsCompleted__c) {
                        clm.Status = oldClmList.get(clm.Id).Status;
                        clm.ARC_VRHelper__c = !clm.ARC_VRHelper__c;
                        clm.ARC_AllSMBItemsDenied__c = false;
                    }
                    else if (clm.ARC_AreItemsClosed__c && claimsSMBDenied.get(clm.Id) != null && claimsSMBDenied.get(clm.Id) == true) {
                        //clm.Status = oldClmList.get(clm.Id).Status;
                        clm.ARC_VRHelper__c = !clm.ARC_VRHelper__c;
                        clm.ARC_AllSMBItemsDenied__c = true;
                    }
                    else if (clm.ARC_AreItemsClosed__c  && claimsSMBDenied.get(clm.Id) != null && claimsSMBDenied.get(clm.Id) == false) {
                        clm.ARC_VRHelper__c = !clm.ARC_VRHelper__c;
                        clm.ARC_AllSMBItemsDenied__c = false;
                    }
                }
            }
        }
    }

    public static Boolean XMLFiledsCheckMember(Claim c) {
        
        if (c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account.BillingStreet != null &&
            c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account.BillingCity != null &&
            c?.ARC_PrimaryMemberCM__r?.vlocity_ins__ContactId__r?.Account.BillingState != null &&
            c?.ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r?.Account.BillingPostalCode != null
        ) {
            return true;
        }
        else {
            return false;
        }
    }

    public static Boolean XMLFiledsCheckProvider (Claim c) {
        if (c.ARC_PayToStreet__c == null || c.ARC_PayToCity__c == null || c.ARC_PayTo_State__c == null || c.ARC_PayTo_ZipCode__c == null) {
            return false;
        }
        //else return true;    
        else return validateZipCode(c.ARC_PayTo_ZipCode__c);    
    }

    public static Boolean validateZipCode(String zipCode) {
        if (String.isBlank(zipCode)) {
            return false; // ZIP code cannot be blank or null
        }
        
        // Remove hyphens if present to check for 9-digit format
        String cleanedZipCode = zipCode.replaceAll('-', '');
        
        // Check if the cleaned ZIP code consists of only numeric characters
        if (!isStringNumeric(cleanedZipCode)) {
            return false; 
        }
        
        // Check if the ZIP code is in one of the valid formats
        if (cleanedZipCode.length() == 5 || cleanedZipCode.length() == 9) {
            return true;
        }
        
        return false; // ZIP code doesn't match the valid formats
    }
    
    public static Boolean isStringNumeric(String inputString) {
        if (String.isNotBlank(inputString)) {
            // Define a regular expression pattern for numeric characters
            Pattern numericPattern = Pattern.compile('^[0-9]+$');
            
            // Use a Matcher to check if the inputString matches the numeric pattern
            Matcher numericMatcher = numericPattern.matcher(inputString);
            
            // Return true if the inputString contains only numeric characters, otherwise false
            return numericMatcher.matches();
        }
        return false; 
    }

    // Check owner control
    public static void ownerControl (Map<Id, Claim> oldClmList, Map<Id, Claim> newClmList) {        
        for (Id newClmId : newClmList.keySet()) {
            Claim nClaim = newClmList.get(newClmId);
            Claim oClaim = oldClmList.get(newClmId);

            if (oClaim.OwnerId != nClaim.Owned_By__c || nClaim.OwnerId != oClaim.Owned_By__c) {
                if (oClaim.Owned_By__c != nClaim.Owned_By__c) {
                    nClaim.OwnerId = nClaim.Owned_By__c;
                } else if (oClaim.OwnerId != nClaim.OwnerId) {
                    nClaim.Owned_By__c = nClaim.OwnerId;
                }
            }
        }
    }
    
    public static void updateNameManualSMB(List<Claim> oldClmList, List<Claim> newClmList) {
        List<Claim> claimsToUpdate = new List<Claim>();
        Boolean isUpdate = false;

        if (oldClmList == null) {
            claimsToUpdate = newClmList;
        } else {
            Map<Id, Claim> oldClaimsMap = new Map<Id, Claim>(oldClmList);
            Map<Id, Claim> newClaimsMap = new Map<Id, Claim>(newClmList);
            for (Id claimId : oldClaimsMap.keySet()) {
                Claim oldc = oldClaimsMap.get(claimId);
                Claim newc = newClaimsMap.get(claimId);
                if (oldc.ARC_Paper_Claim_Type__c != newc.ARC_Paper_Claim_Type__c) {
                    claimsToUpdate.add(newClaimsMap.get(claimId));
                    isUpdate = true;
                }
            }
        }

        for (Claim c: claimsToUpdate) {
            String smbName;
            if (c.ARC_ClaimInput__c == null && c.Name != null && !c.Name.contains('- A') && !c.Name.contains('- C') && !c.Name.contains('- REASSINMENT')) {
                if (isUpdate) {
                    smbName = c.Name.substring(0, 17);
                } else {
                    smbName = DateTime.now().format('yyyyMMddHHmmssSSS');
                }

                if (c.ARC_QwikPay__c) {
                    smbName += ' QWICK PAY';
                } else {
                    switch on c.ARC_Paper_Claim_Type__c {
                        when 'Appeals' {
                            smbName += ' - WS1';
                        }
                        when 'Adjustments' {
                            smbName += ' - WS2';
                        }
                        when 'Service Exceptions' {
                            smbName += ' - WS3';
                        }
                        when 'Offboarding Exceptions' {
                            smbName += ' - WS4';
                        }
                        when 'AIDD' {
                            smbName += ' - WS5';
                        }
                        when 'SMART' {
                            smbName += ' - WS6';
                        }
                        when 'Member Reimbursement' {
                            smbName += ' - WS7';
                        }
                        when 'Manual Processing Pricing' { 
                            smbName += ' - WS8';
                        }
                        when 'Itemized Bill' { 
                            smbName += ' - WS9';
                        }
                        when else {
                            smbName += ' - M';
                        }
                    }
                }
                c.Name = smbName;
                if (!Test.isRunningTest()) c.SourceSystemIdentifier = smbName;
            }
        }
    }

    public static void clmCovForClmWithoutInput(List<Claim> cList) {
        List<ClaimCoverage> ccToInsert = new List<ClaimCoverage>();
        for (Claim c: cList) {
            if (c.ARC_ClaimInput__c == null && c.ARC_InputJSON__c == null) {
                ClaimCoverage cc = new ClaimCoverage();
                cc.Name = 'Not covered';
                cc.ClaimId = c.Id;
                cc.InternalReserveMode = 'CoverageReserve';
                ccToInsert.add(cc);
            }
        }
        insert ccToInsert;
    }

    public static void quickPayAAUpdateSMB(Map<Id, Claim> oldClmMap, Map<Id, Claim> newClmMap) {
        List<ARC_ClaimReasonCode__c> crcToInsert = new List<ARC_ClaimReasonCode__c>();
        List<ClaimPaymentSummary> cpsToInsert = new List<ClaimPaymentSummary>();
        List<ClaimCoveragePaymentDetail> lineItemsToUpdate = new List<ClaimCoveragePaymentDetail>();
        Set<Id> claimsId = new Set<Id>();
        Boolean isPaid = false;
            
        for (Id clmId : newClmMap.keySet()) {   
            if (newClmMap.get(clmId).ARC_QwikPay__c == true && oldClmMap.get(clmId).ARC_QwikPay__c == false) {
                claimsId.add(clmId);
            }
        }
        if (claimsId.isEmpty()) {
            return;
        }

        Id idRARC = Schema.SObjectType.vlocity_ins__VlocityCode__c.getRecordTypeInfosByName().get('RARC').getRecordTypeId();
        String infoCode = System.Label.ARC_GeneralCodeInformational;
        vlocity_ins__VlocityCode__c generalInfCode = [SELECT Id, Name, RecordTypeId, ARC_Status__c FROM vlocity_ins__VlocityCode__c WHERE (Name =: infoCode AND  RecordTypeId =: idRARC AND ARC_Status__c = 'Informational') LIMIT 1];
        List<Claim> claimsForAA = [SELECT Id, Name, ARC_MemberContact__c, ARC_PrimaryMemberCM__c, ARC_ParticipantPolicyParticipant__c, ARC_Primary_Member__c, PolicyNumberId, ARC_TotalNetPaidAmount__c, (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim WHERE Id IN :claimsId LIMIT 1000];   
        for (Claim clm : claimsForAA) {              
            // if (clm.ARC_MemberContact__c == null || clm.ARC_PrimaryMemberCM__c == null || clm.ARC_Primary_Member__c == null || clm.ARC_ParticipantPolicyParticipant__c == null || clm.PolicyNumberId == null) {
            //     clm.Status = 'AA Pending for Review';
            //     isPaid = false;
            // } else {
            //     isPaid = true;
            //     clm.Status = 'AA Approved';
            //     clm.ARC_AreItemsClosed__c = true;
            // }
            if (clm.Name.contains('- M')) clm.Name = clm.Name.remove('- M');
            clm.Name += ' QWICK PAY';
            clm.ARC_CheckNumber__c = null;
            clm.ARC_TotalNetPaidAmount__c = 0;

            for (ClaimCoveragePaymentDetail lineItem : clm.Claim_Coverage_Payment_Details__r) {
                ARC_ClaimReasonCode__c crc = new ARC_ClaimReasonCode__c();
                crc.ARC_ClaimCoveragePaymentDetail__c = lineItem.Id;
                crc.ARC_ReasonCode__c = generalInfCode.Id;
                crcToInsert.add(crc);
                if (!isPaid) {
                    lineItem.Status = 'Informational';
                }
                // else {
                //     lineItem.Status = 'Paid';
                //     ClaimPaymentSummary cps = new ClaimPaymentSummary();
                //     cps.Name = 'Payment of item: ' + lineItem.Name;
                //     cps.ARC_SMB_Item__c = lineItem.Id;
                //     cps.ClaimId = clm.Id;
                //     cpsToInsert.add(cps);
                // }
                lineItemsToUpdate.add(lineItem);
            }
        }
        insert crcToInsert; // ARC_ClaimReasonCode__c
        if (cpsToInsert.size() > 0) {
            insert cpsToInsert; //ClaimPaymentSummary
            for (ClaimPaymentSummary cps : cpsToInsert) {
                for (ClaimCoveragePaymentDetail lineItem : lineItemsToUpdate) {
                    if (cps.ARC_SMB_Item__c == lineItem.Id) lineItem.ClaimPaymentSummaryId = cps.Id;
                }
            }
        }

        update lineItemsToUpdate;
        update claimsForAA;
    }

    public static void populateCheckNumber(Map<Id, Claim> oldClmMap, Map<Id, Claim> newClmMap) {
        Set<Id> claimsId = new Set<Id>();
        List<Claim> claimsToUpdate = new List<Claim>();
        for (Id clmId : newClmMap.keySet()) {
            if (oldClmMap.get(clmId).ARC_CheckRun__c == null && newClmMap.get(clmId).ARC_CheckRun__c != null) {
                claimsToUpdate.add(newClmMap.get(clmId));
            }
        }
        if (claimsToUpdate.size() > 0) {

            // Create a map to track new check numbers and claims
            Map<Claim, String> checkNumberMap = new Map<Claim, String>();

            Decimal checkNumber = ARC_XMLCounter__c.getInstance('ZelisCheck').ARC_CheckNumber__c;
            for (Claim clm : claimsToUpdate) {
                checkNumber = checkNumber + 1;
                String newCheckNumber;
                if (clm.ARC_TotalNetPaidAmount__c == 0) newCheckNumber = 'NC' + String.valueOf(Integer.valueOf(checkNumber));
                else if (clm.ARC_TotalNetPaidAmount__c > 0) newCheckNumber = String.valueOf(Integer.valueOf(checkNumber));
                checkNumberMap.put(clm,newCheckNumber);
            }
            List<Claim> existingClaims = [SELECT Id, ARC_CheckNumber__c FROM Claim WHERE ARC_CheckNumber__c IN :checkNumberMap.values() AND HaxSMB__c != true ];
            
            Map<String, Claim> existingCheckNumbersMap = new Map<String, Claim>();
            if (existingClaims.size() > 0) {
               for (Claim existingClm : existingClaims) {
                    existingCheckNumbersMap.put(existingClm.ARC_CheckNumber__c, existingClm);
                }
            }

            for (Claim clm : claimsToUpdate) {
                String newCheckNumber = checkNumberMap.get(clm);
                if (existingClaims.size() > 0) {
                    if (existingCheckNumbersMap.get(newCheckNumber)!=null) {
                        clm.addError('Duplicate Check Number, contact an admin!');
                    }
                } else {
                    clm.ARC_CheckNumber__c = newCheckNumber;
                }
            }

            //Update the check number counter if needed. 
            ARC_XMLCounter__c checkNumberCounter = ARC_XMLCounter__c.getInstance('ZelisCheck');
            if (checkNumberCounter.ARC_CheckNumber__c !=  checkNumber) {
                checkNumberCounter.ARC_CheckNumber__c = checkNumber;
                update checkNumberCounter;
            } 
        }
    }

    public static void refundCalculation(Map<Id, Claim> oldClms, Map<Id, Claim> newClms) {

        for (String clmId : newClms.keySet()) {
            if (
                (oldClms.get(clmId).ARC_Refund__c == false && newClms.get(clmId).ARC_Refund__c == true) || 
                (oldClms.get(clmId).ARC_Refund__c == true && newClms.get(clmId).ARC_Refund__c == false) ||
                (oldClms.get(clmId).ARC_RefundAmount__c != newClms.get(clmId).ARC_RefundAmount__c)
            ) {
                Claim newClaim = (Claim)newClms.get(clmId);
                Claim oldClaim = (Claim)oldClms.get(clmId);

                // ADD OR REMOVE "REFUND" FROM NAME
                if (oldClaim.ARC_Refund__c == false && newClaim.ARC_Refund__c == true) {
                    if (!newClaim.Name.contains(' - REFUND')) newClaim.Name = newClaim.Name + ' - REFUND';
                } else if (oldClaim.ARC_Refund__c == true && newClaim.ARC_Refund__c == false) {
                    if (newClaim.Name.contains(' - REFUND')) newClaim.Name = newClaim.Name.replace(' - REFUND', '');
                }

                // CALCULATE THE AMOUNT
                Double previousAmount = oldClaim.ARC_RefundAmount__c != null ? oldClaim.ARC_RefundAmount__c : 0;
                if (newClaim.ARC_RefundAmount__c != null && newClaim.ARC_Refund__c == true) {
                    Double currentAmount = newClaim.ARC_RefundAmount__c;

                    newClaim.ARC_TotalNetPaidAmount__c += previousAmount;
                    newClaim.ARC_TotalNetPaidAmount__c -= currentAmount;
                } else if (
                    newClaim.ARC_RefundAmount__c == 0 || 
                    newClaim.ARC_RefundAmount__c == null || 
                    newClaim.ARC_Refund__c == false
                ) {
                    newClaim.ARC_TotalNetPaidAmount__c += previousAmount;
                }
                
                newClaim.ARC_VRHelper__c = !oldClaim.ARC_VRHelper__c;
            }
        }
    }
    
    public static void extractClaimSubmitter(List<Claim> claims) {
        for (Claim cl : claims) {
            cl.Claim_Submitter__c = null; // clear previous value unless replaced
            
            if (String.isNotBlank(cl.ARC_SubmitterJSON__c)) {
                try {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(cl.ARC_SubmitterJSON__c);
                    Object val = parsed.get('SubmitterName.ResponseContactLastorOrganizationName_03');
                    if (val != null) {
                        cl.Claim_Submitter__c = String.valueOf(val).trim();
                    }
                } catch (Exception e) {
                    // already null — safe to skip
                }
            }
        }
    }
    
    // Add this method to ARC_ClaimTriggersHandler
    public static Set<Id> getOptumClaimIds(Map<Id, Claim> claimMap) {
        Set<Id> checkRunIds = new Set<Id>();
        Set<Id> optumClaimIds = new Set<Id>();
        
        // Collect all CheckRun IDs from the claims
        for (Claim claim : claimMap.values()) {
            if (claim.ARC_CheckRun__c != null) {
                checkRunIds.add(claim.ARC_CheckRun__c);
            }
        }
        
        if (checkRunIds.isEmpty()) return optumClaimIds;
        
        // Query CheckRuns to find Optum processors
        Map<Id, ARC_CheckRun__c> checkRuns = new Map<Id, ARC_CheckRun__c>([
            SELECT Id, Processor__c 
            FROM ARC_CheckRun__c 
            WHERE Id IN :checkRunIds
        ]);
        
        // Find claims associated with Optum CheckRuns
        for (Claim claim : claimMap.values()) {
            if (claim.ARC_CheckRun__c != null) {
                ARC_CheckRun__c checkRun = checkRuns.get(claim.ARC_CheckRun__c);
                if (checkRun != null && checkRun.Processor__c == 'Optum') {
                    optumClaimIds.add(claim.Id);
                }
            }
        }
        
        return optumClaimIds;
    }
    
    public static List<Map<Id, Claim>> filterZelisClaims(Map<Id, Claim> oldMap, Map<Id, Claim> newMap, Map<Id, String> checkRunProcessors) {
        Map<Id, Claim> zelisOldMap = new Map<Id, Claim>();
        Map<Id, Claim> zelisNewMap = new Map<Id, Claim>();
        
        for (Id claimId : newMap.keySet()) {
            Claim newClaim = newMap.get(claimId);
            String processor = checkRunProcessors.get(newClaim.ARC_CheckRun__c);
            
            // Include if processor is Zelis or blank (default to Zelis)
            if (processor == 'Zelis' || String.isBlank(processor)) {
                zelisNewMap.put(claimId, newClaim);
                if (oldMap != null) {
                    zelisOldMap.put(claimId, oldMap.get(claimId));
                }
            }
        }
        
        List<Map<Id, Claim>> result = new List<Map<Id, Claim>>();
        result.add(zelisOldMap);
        result.add(zelisNewMap);
        return result;
    }
}