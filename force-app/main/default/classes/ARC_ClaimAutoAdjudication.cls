public with sharing class ARC_ClaimAutoAdjudication {
    public static final String DUPLICATE_CLAIM = 'Duplicate SMB';
    public static final String DOS_BEFORE = 'SMB DOS before Policy Effective Date';
    public static final String DOS_AFTER = 'SMB DOS after Policy Expiration Date';
    public static final String CODE_HS900 = 'Code HS900 added to line items';
    public static final String CODE_PH900 = 'Code PH900 added to line items';
    public static final String CODE_HS901 = 'Code HS901 added to line items';
    public static final String CODE_HT902 = 'Code HT902 added to line items';


    public static final List<String> CODES = new List<String>{'HS900', 'PH900', 'HS901', 'HT902', 'A0006','ELIG00', 'ELIG01', 'ELIG02', '3075F', '3079F'};
    public static void autoAdjudicateClaim(List<Id> claimsId){
        List<Claim> claimsForAA = [SELECT Id, 
        ARC_CCToCompare__c, 
        ARC_NTE837IBNoteSegment__c, 
        ARC_Duplicate__c,
        ARC_MemberContact__c,
        PolicyNumberId,
        ARC_PatientCensusMember__c,
        Status, 
        ARC_DOSFrom__c, 
        ARC_DOSTo__c, 
        PolicyNumber.ARC_isActive__c, 
        PolicyNumber.ARC_EffectiveDate__c, 
        PolicyNumber.ARC_ExpirationDate__c, 
        (SELECT Id, Name, Status, ARC_Allowed__c, ARC_ProcedureCode__c, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
        FROM Claim WHERE Id IN :claimsId LIMIT 1000];
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
        Boolean claimStatusChanged = false;


        for(Claim clm : claimsForAA){
            Date effectiveDate = clm?.PolicyNumber?.ARC_EffectiveDate__c;
            Date expirationDate = clm?.PolicyNumber?.ARC_ExpirationDate__c;
            Boolean isActive = clm?.PolicyNumber?.ARC_isActive__c;

            for(ClaimCoveragePaymentDetail lineItem : clm.Claim_Coverage_Payment_Details__r ){
                if(clm.ARC_Duplicate__c){
                    ARC_ClaimReasonCode__c crc = new ARC_ClaimReasonCode__c();
                    crc.ARC_ClaimCoveragePaymentDetail__c = lineItem.Id;
                    crc.ARC_ReasonCode__c = ((vlocity_ins__VlocityCode__c)generalCodeMap.get('A0006')).Id;
                    crcToInsert.add(crc);
                    lineItem.Status = 'Denied';
                    lineItemsToUpdate.add(lineItem);
                    clm.Status = 'AA Denied';
                    clm.ARC_AutoAdjudicationReview__c = DUPLICATE_CLAIM;    
                }else if(clm.ARC_DOSTo__c < effectiveDate){ 
                    ARC_ClaimReasonCode__c crc = new ARC_ClaimReasonCode__c();
                    crc.ARC_ClaimCoveragePaymentDetail__c = lineItem.Id;
                    crc.ARC_ReasonCode__c = ((vlocity_ins__VlocityCode__c)generalCodeMap.get('ELIG01')).Id;
                    crcToInsert.add(crc);
                    lineItem.Status = 'Denied';
                    lineItemsToUpdate.add(lineItem);
                    clm.Status = 'AA Denied';
                    clm.ARC_AutoAdjudicationReview__c = DOS_BEFORE;
                }else if( clm.ARC_DOSFrom__c > expirationDate || (clm.PolicyNumberId == null && clm.ARC_MemberContact__c != null && clm.ARC_PatientCensusMember__c != null)){ 
                    ARC_ClaimReasonCode__c crc = new ARC_ClaimReasonCode__c();
                    crc.ARC_ClaimCoveragePaymentDetail__c = lineItem.Id;
                    crc.ARC_ReasonCode__c = ((vlocity_ins__VlocityCode__c)generalCodeMap.get('ELIG02')).Id;
                    crcToInsert.add(crc);
                    lineItem.Status = 'Denied';
                    lineItemsToUpdate.add(lineItem);
                    clm.Status = 'AA Denied';
                    clm.ARC_AutoAdjudicationReview__c = DOS_AFTER;
                }else if (lineItem?.ARC_Allowed__c > 0 && lineItem?.ARC_ProcedureCode__c != ((vlocity_ins__VlocityCode__c)generalCodeMap.get('3075F')).Id && lineItem?.ARC_ProcedureCode__c != ((vlocity_ins__VlocityCode__c)generalCodeMap.get('3079F')).Id){
                    if(clm.ARC_NTE837IBNoteSegment__c != null && clm.ARC_NTE837IBNoteSegment__c.contains('#HET')){
                        ARC_ClaimReasonCode__c crc = new ARC_ClaimReasonCode__c();
                        crc.ARC_ClaimCoveragePaymentDetail__c = lineItem.Id;
                        crc.ARC_ReasonCode__c = ((vlocity_ins__VlocityCode__c)generalCodeMap.get('HS900')).Id;
                        crcToInsert.add(crc);
                        lineItem.Status = 'Informational';
                        lineItemsToUpdate.add(lineItem);
                        clm.ARC_AutoAdjudicationReview__c = CODE_HS900;
    
                    } else if (clm.ARC_NTE837IBNoteSegment__c != null && clm.ARC_NTE837IBNoteSegment__c.contains('#GJ5')){
                        ARC_ClaimReasonCode__c crc = new ARC_ClaimReasonCode__c();
                        crc.ARC_ClaimCoveragePaymentDetail__c = lineItem.Id;
                        crc.ARC_ReasonCode__c = ((vlocity_ins__VlocityCode__c)generalCodeMap.get('PH900')).Id;
                        crcToInsert.add(crc);
                        lineItem.Status = 'Informational';
                        lineItemsToUpdate.add(lineItem);
                        clm.ARC_AutoAdjudicationReview__c = CODE_PH900;
    
                    } else if (clm.ARC_NTE837IBNoteSegment__c != null && clm.ARC_NTE837IBNoteSegment__c.contains('#HES')){
                        ARC_ClaimReasonCode__c crc = new ARC_ClaimReasonCode__c();
                        crc.ARC_ClaimCoveragePaymentDetail__c = lineItem.Id;
                        crc.ARC_ReasonCode__c = ((vlocity_ins__VlocityCode__c)generalCodeMap.get('HS901')).Id;
                        crcToInsert.add(crc);
                        lineItem.Status = 'Informational';
                        lineItemsToUpdate.add(lineItem);
                        clm.ARC_AutoAdjudicationReview__c = CODE_HS901;
    
                    } else if (clm.ARC_NTE837IBNoteSegment__c != null && clm.ARC_NTE837IBNoteSegment__c.contains('#HEU')){
                        ARC_ClaimReasonCode__c crc = new ARC_ClaimReasonCode__c();
                        crc.ARC_ClaimCoveragePaymentDetail__c = lineItem.Id;
                        crc.ARC_ReasonCode__c = ((vlocity_ins__VlocityCode__c)generalCodeMap.get('HT902')).Id;
                        crcToInsert.add(crc);
                        lineItem.Status = 'Informational';
                        lineItemsToUpdate.add(lineItem);
                        clm.ARC_AutoAdjudicationReview__c = CODE_HT902;
                    }
                }
            }  
            claimsToUpdate.add(clm);   
        }
        insert crcToInsert; // ARC_ClaimReasonCode__c
        update lineItemsToUpdate;     
        try{
            Database.update(claimsToUpdate, false);
        } catch (Exception e){
            System.debug('Error updating claim:' + e.getMessage());
        }
    }
}