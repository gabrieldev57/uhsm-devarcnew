/*******************************************************************
 * @ClassName          :   ARC_ReassignmentSMB
 * @Description        :   Apex class to reassign a closed SMB claim to a different member
 *                         It creates a new claim cloned from the original one, with the new member as patient.
 *                         The original claim and its items are voided.
 *                         voiding the original claim will reassign the consumed values to the new member's aggregators
 *                           
 * 
 * @lastModified       :   2025-10-13
 ********************************************************************/
public without sharing class ARC_ReassignmentSMB {
    public class inputRequest {
        @InvocableVariable(label = 'Claim Id' required=true)
        public String claimId;
        @InvocableVariable(label = 'New Participant ContactId' required=true)
        public String newContactId;
        @InvocableVariable(label = 'Insurance Policy Participants listed' required=true)
        public List<InsurancePolicyParticipant> InsurancePolicyParticipantsList;
    }

    public class ARC_ReassignmentClaimResult {
        @InvocableVariable
        public Id newClaimId;
        @InvocableVariable
        public String newClaimLink;
        @InvocableVariable
        public String errorMessage;
    }

    
    /*********************************************************************************************************     * 
     * @name            createSMBReassignment     * 
     * @description     Invokable Method for Member reassignment    *
     * @param           inputRequest[] request   * 

     * *********************************************************************************************************/
    @InvocableMethod(label='Reassign SMB' description='Reassign the closed Claim to a different member')
    public static List<ARC_ReassignmentClaimResult> createSMBReassignment(inputRequest[] request) {
        
        List<ARC_ReassignmentClaimResult> result = new List<ARC_ReassignmentClaimResult>();
        Id claimId = request[0].claimId;
        Id newContactId = request[0].newContactId;
        List<InsurancePolicyParticipant> InsurancePolicyParticipantsList = request[0].InsurancePolicyParticipantsList;
        InsurancePolicyParticipant polPart;
        
        String claimF = System.Label.ARC_FieldForClaimCopy1 + System.Label.ARC_FieldForClaimCopy2;
        Claim originalClaim = Database.query('SELECT ' + claimF + ', ARC_OriginalSMB__c, ARC_OriginalSMB__r.ARC_CheckNumber__c, ARC_CheckRun__c, ARC_CheckNumber__c, ARC_CheckRunApproval__c FROM Claim WHERE Id = ' + '\''+ claimId + '\'' + 'LIMIT 1');

        for(InsurancePolicyParticipant ipp :InsurancePolicyParticipantsList){
            if(ipp.PrimaryParticipantContactId == newContactId){
                polPart = ipp;
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            ARC_ReassignmentClaimResult res = createClaimReassignment(originalClaim, polPart, newContactId);
            result.add(res);
            if(res.errorMessage != null){
                Database.rollback(sp);
                throw new FlowException('Claim Reassignment error: ' + res.errorMessage);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw new FlowException('Error reassigning SMB: ' + e.getMessage());
        }
        return result;
    }

    /*********************************************************************************************************     * 
     * @name            createClaimReassignment     * 
     * @description     Method to create a new Claim cloned from the original one, with the new member as patient.     *
     * @param           Claim originalClaim   * 
     * @param           InsurancePolicyParticipant newPolPart   * 
     * @param           String newContactId   *
     * *********************************************************************************************************/
    public static ARC_ReassignmentClaimResult createClaimReassignment(Claim originalClaim, InsurancePolicyParticipant newPolPart, String newContactId) {
        //List<Claim> claimsToUpsert = new List<Claim>();
        ARC_ReassignmentClaimResult result = new ARC_ReassignmentClaimResult();
        List<ClaimCoveragePaymentDetail> itemsToInsert = new List<ClaimCoveragePaymentDetail>();
        List<ARC_Institutional_Claim_Code__c> instCodesToInsert = new List<ARC_Institutional_Claim_Code__c>();

        List<Claim> claims = new List<Claim>();
        
        // CREATE NEW CLAIM
        Claim newClaim = originalClaim.clone(false, false, false, false);
        newClaim.SourceSystemIdentifier = String.valueOf(DateTime.now().getTime()); // to ensure uniqueness
        newClaim.ARC_OriginalSMB__c = originalClaim.Id ;
        /// ----> newClaim.ARC_CheckNumber__c  = originalClaim.ARC_CheckNumber__c + 1;

        // CHECK NUMBER HAS TO BE UNIQUE, EDIT ORIGINAL CLAIM TO MAINTAIN CHECK NUMBER 
        String newCheckNumber;
        Integer voidCount = 1;
        // if original claim is reassignment, take base check number from its original claim (not from itself)
        // Only run this if the Claim Name indicates a reassignment

        if (originalClaim.Name != null && originalClaim.Name.containsIgnoreCase('- REASSIGNMENT')) {
            // Use the check number from the original SMB (base claim)
            String baseNumber = (originalClaim.ARC_OriginalSMB__r != null)
                ? originalClaim.ARC_OriginalSMB__r.ARC_CheckNumber__c
                : originalClaim.ARC_CheckNumber__c;

            if (baseNumber != null) {
                Pattern pattern = Pattern.compile('(?i)( -Reassigned)(\\((\\d+)\\))?'); // case-insensitive
                Matcher matcher = pattern.matcher(baseNumber);

                if (matcher.find()) {
                    // If a number already exists, increment it
                    String currentNumber = matcher.group(3);
                    if (currentNumber != null) {
                        voidCount = Integer.valueOf(currentNumber) + 1;
                    } else {
                        voidCount = 2; // first void after base "- voided"
                    }
                    // Replace the "- voided" part (and optional (n)) with the new one
                    newCheckNumber = matcher.replaceFirst(matcher.group(1) + '(' + voidCount + ')');
                } else {
                    // No "- voided" found, append it
                    newCheckNumber = baseNumber + ' -Reassigned';
                }
            }
        } else {
            // No reassignment: just append "- voided" directly
            if (originalClaim.ARC_CheckNumber__c != null) {
                newCheckNumber = originalClaim.ARC_CheckNumber__c + ' -Reassigned';
            }
        }
        originalClaim.ARC_CheckNumber__c = newCheckNumber;

        // CHANGE PATIENT 
        vlocity_ins__GroupCensusMember__c newCensusMember = [SELECT Id, vlocity_ins__ContactId__c, vlocity_ins__RelatedCensusMemberId__c, vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__ContactId__c =: newContactId LIMIT 1];
        newClaim.ARC_PatientCensusMember__c = newCensusMember.Id;
        newClaim.ARC_MemberContact__c = newContactId;
        newClaim.ARC_ParticipantPolicyParticipant__c = newPolPart.Id; // policy participant Id needed
        if(newCensusMember.vlocity_ins__RelatedCensusMemberId__c == null){
            newClaim.ARC_PrimaryMemberCM__c = newCensusMember.Id;
            newClaim.ARC_Primary_Member__c = newPolPart.PrimaryParticipantContactId;
        } else{
            newClaim.ARC_PrimaryMemberCM__c = newCensusMember.vlocity_ins__RelatedCensusMemberId__c;
            newClaim.ARC_Primary_Member__c = newCensusMember.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c; 
        }

        try {
            update originalClaim;
            insert newClaim;
            result.newClaimLink = URL.getOrgDomainUrl().toExternalForm() + '/' + newClaim.Id;
            result.newClaimId = newClaim.Id; 
        } catch (Exception ex) {
            String errorMessage = 'Error while inserting new Claim: '+ ex.getMessage();
            result.errorMessage = errorMessage;
            return result;
        }

        // INSERT NEW CLAIM COVERAGE
        ClaimCoverage cc = [SELECT Id, Name, ClaimId, InternalReserveMode FROM ClaimCoverage WHERE ClaimId =: originalClaim.Id LIMIT 1];
        ClaimCoverage newCC = cc.clone(false, true, false, false);
        newCC.ClaimId = newClaim.Id;
        try {
            insert newCC;
        } catch (Exception ex) {
            String errorMessage = 'Error while inserting new Claim Coverage: ' + ex.getMessage();
            result.errorMessage = errorMessage;
            return result;
        }

        // INSERT LINE ITEMS
        String claimItemF = System.Label.ARC_FieldForClaimItemCopy1;
        List<ClaimCoveragePaymentDetail> newCLIList = new List<ClaimCoveragePaymentDetail>();
        List<ClaimCoveragePaymentDetail> paidCLIList = new List<ClaimCoveragePaymentDetail>(); // to process item payments later
        List<ClaimCoveragePaymentDetail> deniedCLIList = new List<ClaimCoveragePaymentDetail>(); // to process insert and change status later
        List<ARC_ClaimReasonCode__c> newReasonCodes = new List<ARC_ClaimReasonCode__c>();
        List<ClaimCoveragePaymentDetail> originalCLIList = Database.query('SELECT ' + claimItemF + ', Status, ARC_MaximumType__c, ARC_MaximumTypeAmount__c, (SELECT Id, ARC_ClaimCoveragePaymentDetail__c, ARC_ReasonCode__c FROM Claim_Reason_Codes__r) FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =\'' + String.escapeSingleQuotes(originalClaim.Id) + '\' LIMIT 1000');
        
        for (ClaimCoveragePaymentDetail oCLI : originalCLIList) {
            // clone existing line item
            ClaimCoveragePaymentDetail newCLI = oCLI.clone(false, false, false, false);
            // associate to new claim and new claim coverage
            // verify CLI status
            if (oCLI.Status == 'Paid' || oCLI.Status == 'Denied') {
                newCLI.ARC_Claim__c = newClaim.Id;
                newCLI.ClaimCoverageId = newCC.Id;
                if(oCLI.Status == 'Paid'){
                    newCLI.Status = 'New'; // This status should change to 'Paid' when the item payments are created // TODO> careful for denied items
                    paidCLIList.add(newCLI);
                }else {
                    newCLI.Status = 'New'; // Denied items cannot be inserted (validation rule)
                    deniedCLIList.add(newCLI);
                }
                newCLIList.add(newCLI);
            } else {
                String errorMessage = 'SMBs with unprocessed line items cannot be reassigned.';
            	result.errorMessage = errorMessage;
            	return result;
        	}
        }
        try{
            insert newCLIList;
        } catch (Exception ex) {
            String errorMessage = 'Error while inserting new Claim Line Items: ' + ex.getMessage();
            result.errorMessage = errorMessage;
            return result;
        }

        // UPDATE DENIED ITEMS
        for(ClaimCoveragePaymentDetail cli : deniedCLIList){ // only paid CLI need item payments
            cli.Status = 'Denied';    
        }
        try{
            update deniedCLIList;
        } catch (Exception ex) {
            String errorMessage = 'Error while updating Claim Line Items to Denied: ' + ex.getMessage();
            result.errorMessage = errorMessage;
            return result;
        }

        // INSERT CLAIM REASON CODES FOR THE NEW CLIs
        for (Integer i = 0; i < originalCLIList.size(); i++) {
            ClaimCoveragePaymentDetail oCLI = originalCLIList[i];
            ClaimCoveragePaymentDetail nCLI = newCLIList[i];
    
            for (ARC_ClaimReasonCode__c reason : oCLI.Claim_Reason_Codes__r) {
                ARC_ClaimReasonCode__c newReason = reason.clone(false, false, false, false);
                newReason.ARC_ClaimCoveragePaymentDetail__c = nCLI.Id;
                newReasonCodes.add(newReason);
            }
        }
        try {
            insert newReasonCodes;
        } catch (Exception ex) {
            String errorMessage = 'Error while inserting new Claim Reason Codes: ' + ex.getMessage();
            result.errorMessage = errorMessage;
            return result;
        }
        
        // INSERT INSTITUTIONAL CLAIM CODES
        List<ARC_Institutional_Claim_Code__c> claimCodes = [
            SELECT ARC_Amount__c, ARC_ConditionCode__c, ARC_Date__c, ARC_Date_From__c, ARC_Date_Through__c, ARC_ECodes__c, ARC_ICD_DX__c, ARC_Institutional_Claim__c, ARC_Occurrence_Code__c, ARC_Occurrence_Span_Code__c, ARC_Other_Procedure_Code__c, ARC_Patient_DX__c, ARC_POA__c, ARC_Vale_Codes__c 
            FROM ARC_Institutional_Claim_Code__c 
            WHERE ARC_Institutional_Claim__c =: originalClaim.Id 
            LIMIT 1000
        ];
        for (ARC_Institutional_Claim_Code__c instC : claimCodes) {
            ARC_Institutional_Claim_Code__c clmCode = instC.clone(false, false, false, false);
            clmCode.ARC_Institutional_Claim__c = newClaim.Id;
            instCodesToInsert.add(clmCode);
        }

        try {
            insert instCodesToInsert;
        } catch (Exception ex) {
            String errorMessage = 'Error while inserting new Institutional Claim Codes' + ex.getMessage();
            result.errorMessage = errorMessage;
            return result;
        }    

        try {
            String newSMBName;
            Integer reassignments = 1; 

            if (originalClaim.Name != null) {
                String baseName = originalClaim.Name;
                Pattern pattern = Pattern.compile('(?i)(- REASSIGNMENT)(\\((\\d+)\\))?'); // case-insensitive
                Matcher matcher = pattern.matcher(baseName);

                if (matcher.find()) {
                    // Check if a number already exists inside parentheses
                    String currentNumber = matcher.group(3);
                    if (currentNumber != null) {
                        reassignments = Integer.valueOf(currentNumber) + 1;
                    } else {
                        reassignments = 2; // first reassignment after base "- REASSIGNMENT"
                    }
                    // Replace only the "- REASSIGNMENT" part (and optional (n)) with the new one
                    newSMBName = matcher.replaceFirst(matcher.group(1) + '(' + reassignments + ')');
                } else {
                    // No "- REASSIGNMENT" found, append it at the end
                    newSMBName = baseName + ' - REASSIGNMENT';
                }
            }

            newClaim.Name = newSMBName;
            update newClaim;
        } catch (Exception ex) {
            String errorMessage = 'Error naming SMB: ' + ex.getMessage();
            result.errorMessage = errorMessage;
            return result;
        }        

        // VOID ORIGINAL CLAIM BEFORE CREATING ITEM PAYMENTS AND RESTORE AGGREGATORS
        VoidClaim(originalClaim.Id); // .

        // CREATE NEW ITEM PAYMENTS
        List<Id> itemIds = new List<Id>();
        for (ClaimCoveragePaymentDetail cli : paidCLIList) { // only paid CLI need item payments
            itemIds.add(cli.Id);    
        }
        Map<String, Object> inputMap = new Map<String, Object>{
            'itemIds' => itemIds,
            'claimId' => newClaim.Id
        };
        Map<String, Object> outMap = new Map<String, Object>();
        ARC_CoveragePaymentsTableController.createItemPayments(inputMap, outMap);
        if (outMap.containsKey('errorOnUpdate')) {
            String errorMessage = (String) outMap.get('errorOnUpdate');
            result.errorMessage = 'Error creating new Item Payments: ' + errorMessage;
        }
        
        return result;
    }

    /*********************************************************************************************************     * 
     * @name            VoidClaim     * 
     * @description     Method to void the original claim and restore the consumed values to the original aggregators. 
     *                  * based on ARC_VoidClaim.VoidClaim method 
     *                  ** Input parameter is Original claim's Id
     *                  ** It does not remove the claim from checkrun, as the original method does.
     *                  * It throws FlowException in case of errors, to be caught in the calling method.
     * @param           id clmId
     * *********************************************************************************************************/
    public static Boolean VoidClaim(id clmId) {
        Boolean resullt = false;
        try {
            Claim clm = [SELECT Id, Status, ARC_DOSFrom__c, ARC_DOSTo__c, ARC_VRHelper__c, PolicyNumberId, ARC_MemberContact__c, ARC_MemberBenefitPlan__c, 
                        (SELECT Id, Status, ARC_Deductible__c,
                            ARC_Pre_Existing_Condition__c,
                            ARC_Tobacco__c,
                            ARC_Coinsurance__c,
                            ARC_Allowed__c,
                            ARC_Medical_Visit_Reason__c
                        FROM Claim_Coverage_Payment_Details__r),
                        (SELECT Id FROM ClaimPaymentSummaries) 
                    FROM Claim
                    WHERE Id =: clmId];
            vlocity_ins__VlocityCode__c[] denyCode = [SELECT Id FROM vlocity_ins__VlocityCode__c WHERE Name = 'V0001' AND RecordType.Name = 'RARC' AND ARC_Status__c = 'Denied']; 
            List<ARC_ClaimReasonCode__c> itemCodes = new List<ARC_ClaimReasonCode__c>();

            if (denyCode.size() == 0) throw new FlowException('The denied code: V0001 it is not on the system.');

            List<Id> paidCLIIds = new List<Id>();
            for (ClaimCoveragePaymentDetail cli : clm.Claim_Coverage_Payment_Details__r) {
                if(cli.Status == 'Paid'){
                    paidCLIIds.add(cli.Id);  
                }
            }
           
            // RESETTING AGGREGATORS RELIES ON SMB ITEM PAYMENT SUMMARY RECORDS BEING PRESENT
            // IF THEY ARE NOT PRESENT, CALL ARC_CoveragePaymentsTableController.createItemPayments on the original claim's items
            // PASSING FLAG TO MODIFY ONLY THE PAYMENT ITEMS NOR THE AGGREGATORS NOT THE LINE ITEMS
            if (paidCLIIds.size() != 0 && clm.ClaimPaymentSummaries.size() == 0 ) {
                Map<String, Object> inputMap = new Map<String, Object>{
                    'itemIds' => paidCLIIds,
                    'claimId' => clmId,
                    'upsertOnlyPaymentItems' => true // isReassignmentFlow flag to avoid modifying original aggregators 
                };
                
                Map<String, Object> outMap = new Map<String, Object>();
                // method will create the payment items for paid items only
                ARC_CoveragePaymentsTableController.createItemPayments(inputMap, outMap);
                
                if (outMap.containsKey('errorMessage')){
                    String errorMessage = (String) outMap.get('errorMessage');
                    throw new FlowException('Error creating missing SMB Item Summary records on original claim: ' + errorMessage);
                }

            }
            
            // UNLOCK THE CLAIM
            clm.Status = 'Initial';
            clm.ARC_VRHelper__c = !clm.ARC_VRHelper__c;
            update clm;

            // RESET ITEMS AND AGGREGATORS - 1ST JANUARY
            Boolean reseted = ARC_CoveragePaymentsTableController.resetItems(clm, 'void', new Set<Id>()); 
            if (!reseted) {
                
                throw new FlowException('The Line items form original SMB could not be reseted.');
            }

            List<ClaimCoveragePaymentDetail> claimItemsUpdated = [
                SELECT Id, Status, ARC_Deductible__c, ARC_Claim__c
                FROM ClaimCoveragePaymentDetail
                WHERE ARC_Claim__c = :clm.Id
            ];

            // DENY CLAIM AND ITEMS
            for (ClaimCoveragePaymentDetail item : claimItemsUpdated) {
                item.Status = 'Denied';

                ARC_ClaimReasonCode__c itemCode = new ARC_ClaimReasonCode__c();
                itemCode.ARC_ReasonCode__c = denyCode[0].Id;
                itemCode.ARC_ClaimCoveragePaymentDetail__c = item.Id;
                itemCodes.add(itemCode);
            }
            insert itemCodes;
            update claimItemsUpdated;

            // CLOSE THE CLAIM AGAIN
            clm.Status = 'Voided';
            update clm;
            resullt = true;
        } catch (Exception e) {
            throw new FlowException('Error voiding original claim: ' + e.getMessage());            
        }
        return resullt;
    }


}