public with sharing class ARC_ClaimAutoAdjudication {
    public static final String DUPLICATE_CLAIM = 'Duplicate SMB';
    public static final String DOS_BEFORE = 'SMB DOS before Policy Effective Date';
    public static final String DOS_AFTER = 'SMB DOS after Policy Expiration Date';
    public static final String CODE_HS900 = 'Code HS900 added to line items';
    public static final String CODE_PH900 = 'Code PH900 added to line items';
    public static final String CODE_HS901 = 'Code HS901 added to line items';
    public static final String CODE_HT902 = 'Code HT902 added to line items';
    public static final String CODE_HT904 = 'Code HT904 added to line items';

    public static final List<String> CODES = new List<String>{'HS900', 'PH900', 'HS901', 'HT902', 'HT904', 'A0006', 'ELIG01', 'ELIG02', '3075F', '3079F'};

    // Maps a reason code name (e.g. 'HS900') to its ARC_AutoAdjudicationReview__c label.
    private static final Map<String, String> REVIEW_LABEL_BY_CODE = new Map<String, String>{
        'HS900' => CODE_HS900,
        'PH900' => CODE_PH900,
        'HS901' => CODE_HS901,
        'HT902' => CODE_HT902,
        'HT904' => CODE_HT904
    };

    /**
     * Resolve the appropriate reason code name from a billing note segment.
     * Checks Zelis (#-prefixed) patterns first, then Optum plain-text equivalents.
     * Returns null if the note does not match any known pattern.
     */
    private static String resolveReasonCodeName(String note) {
        if (note == null) return null;
        // Zelis format
        if (note.contains('#HET')) return 'HS900';
        if (note.contains('#GJ5')) return 'PH900';
        if (note.contains('#HES')) return 'HS901';
        if (note.contains('#HEU')) return 'HT902';
        // if (note.contains('#HEV')) return 'HT904';
        // Optum format
        if (note.startsWith('140 Pricing'))            return 'HS900';
        if (note == 'A1' || note.startsWith('A1 '))   return 'PH900';
        if (note.startsWith('120 Pricing'))            return 'HS901';
        if (note == 'FNR')                             return 'HT902';
        if (note == 'NEG')                          return 'HT904';
        return null;
    }

    public static void autoAdjudicateClaim(List<Id> claimsId) {
        List<Claim> claimsForAA = [
            SELECT Id,
                ARC_CCToCompare__c,
                ARC_NTE837IBNoteSegment__c,
                ARC_Duplicate__c,
                Status,
                ARC_DOSFrom__c,
                ARC_DOSTo__c,
                PolicyNumber.ARC_isActive__c,
                PolicyNumber.ARC_EffectiveDate__c,
                PolicyNumber.ARC_ExpirationDate__c,
                (SELECT Id, Name, Status, ARC_Allowed__c, ARC_ProcedureCode__c, ARC_Claim__c
                FROM Claim_Coverage_Payment_Details__r)
            FROM Claim
            WHERE Id IN :claimsId
            LIMIT 1000
        ];
        Id idRARC = Schema.SObjectType.vlocity_ins__VlocityCode__c.getRecordTypeInfosByName().get('RARC').getRecordTypeId();
        Id idCPT = Schema.SObjectType.vlocity_ins__VlocityCode__c.getRecordTypeInfosByName().get('CPT').getRecordTypeId();

        Map<String, vlocity_ins__VlocityCode__c> generalCodeMap = new Map<String, vlocity_ins__VlocityCode__c>();
        List<vlocity_ins__VlocityCode__c> generalCodes = [SELECT Id, Name, RecordTypeId, ARC_Status__c FROM vlocity_ins__VlocityCode__c WHERE (RecordTypeId = :idRARC OR RecordTypeId = :idCPT) AND Name IN: CODES LIMIT 5000];
        for (vlocity_ins__VlocityCode__c generalCode : generalCodes) {
            generalCodeMap.put(generalCode.Name, generalCode);
        }

        List<ClaimCoveragePaymentDetail> lineItemsToUpdate = new List<ClaimCoveragePaymentDetail>();
        List<ARC_ClaimReasonCode__c> crcToInsert = new List<ARC_ClaimReasonCode__c>();
        List<Claim> claimsToUpdate = new List<Claim>();

        for (Claim clm : claimsForAA) {
            Date effectiveDate  = clm?.PolicyNumber?.ARC_EffectiveDate__c;
            Date expirationDate = clm?.PolicyNumber?.ARC_ExpirationDate__c;

            // Resolve claim-level denial reason once (not once per line item)
            String adjCode   = null;
            String adjReview = null;
            if      (clm.ARC_Duplicate__c)               { adjCode = 'A0006';  adjReview = DUPLICATE_CLAIM; }
            else if (clm.ARC_DOSTo__c < effectiveDate)   { adjCode = 'ELIG01'; adjReview = DOS_BEFORE;      }
            else if (clm.ARC_DOSFrom__c > expirationDate){ adjCode = 'ELIG02'; adjReview = DOS_AFTER;       }

            if (adjCode != null) {
                Id reasonId = ((vlocity_ins__VlocityCode__c) generalCodeMap.get(adjCode)).Id;
                clm.Status = 'AA Denied';
                clm.ARC_AutoAdjudicationReview__c = adjReview;
                for (ClaimCoveragePaymentDetail lineItem : clm.Claim_Coverage_Payment_Details__r) {
                    crcToInsert.add(new ARC_ClaimReasonCode__c(
                        ARC_ClaimCoveragePaymentDetail__c = lineItem.Id,
                        ARC_ReasonCode__c = reasonId
                    ));
                    lineItem.Status = 'Denied';
                    lineItemsToUpdate.add(lineItem);
                }
            } else {
                String nteName  = resolveReasonCodeName(clm.ARC_NTE837IBNoteSegment__c);
                Id     nteId    = nteName != null ? ((vlocity_ins__VlocityCode__c) generalCodeMap.get(nteName)).Id : null;
                Id     exc3075F = ((vlocity_ins__VlocityCode__c) generalCodeMap.get('3075F')).Id;
                Id     exc3079F = ((vlocity_ins__VlocityCode__c) generalCodeMap.get('3079F')).Id;
                for (ClaimCoveragePaymentDetail lineItem : clm.Claim_Coverage_Payment_Details__r) {
                    if (nteId != null && lineItem?.ARC_Allowed__c > 0
                            && lineItem?.ARC_ProcedureCode__c != exc3075F
                            && lineItem?.ARC_ProcedureCode__c != exc3079F) {
                        crcToInsert.add(new ARC_ClaimReasonCode__c(
                            ARC_ClaimCoveragePaymentDetail__c = lineItem.Id,
                            ARC_ReasonCode__c = nteId
                        ));
                        lineItem.Status = 'Informational';
                        lineItemsToUpdate.add(lineItem);
                        clm.ARC_AutoAdjudicationReview__c = REVIEW_LABEL_BY_CODE.get(nteName);
                    }
                }
            }
            claimsToUpdate.add(clm);
        }
        insert crcToInsert; // ARC_ClaimReasonCode__c
        update lineItemsToUpdate;
        try {
            Database.update(claimsToUpdate, false);
        } catch (Exception e) {
            System.debug('Error updating claim:' + e.getMessage());
        }
    }
}