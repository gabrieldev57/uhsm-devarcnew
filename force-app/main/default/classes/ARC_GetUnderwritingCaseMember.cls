public class ARC_GetUnderwritingCaseMember {

    @AuraEnabled
    (cacheable=true)
    public static Map<String, Object> getUnderwritingCaseMembers(Id caseId){
        Map<String, Object> outputMap = new Map<String, Object>();
        List<ARC_UnderwritingCaseMember__c> underwritingCaseMembers = [
            SELECT Id, 
                ARC_Member__r.vlocity_ins__FirstName__c,
                ARC_Member__r.vlocity_ins__LastName__c, 
                ARC_Member__r.vlocity_ins__Birthdate__c,
                ARC_Member__r.vlocity_ins__SocialSecurityNumber__c,
                ARC_Member__r.vlocity_ins__Gender__c,
                ARC_Member__r.ARC_Height__c,
                ARC_Member__r.ARC_Weight__c,
                ARC_ApprovalResolution__c,
                ARC_FRMLReviewedBy__c,
                ARC_ReviewedBy__c,
                ARC_Score__c,
                ARC_Member__c,
                ARC_Reason__c,
                ARC_Description__c
            FROM ARC_UnderwritingCaseMember__c 
            WHERE ARC_Reason__c NOT IN ('Remove Member', 'Add Newborn') AND ARC_UnderwritingCase__c = :caseId 
            ORDER BY CreatedDate DESC
        ];


        outputMap.put('underwritingCaseMembers', underwritingCaseMembers);

        return outputMap;
    }

    @AuraEnabled
    public static void saveUCMembers(List<Map<String, Object>> ucMembersMapList, Id userId, Id caseId){
        List<ARC_UnderwritingCaseMember__c> underwritingCaseMembers = new List<ARC_UnderwritingCaseMember__c>();
        for (Map<String, Object> ucMemberMap : ucMembersMapList) {
            ARC_UnderwritingCaseMember__c underCaseMember = new ARC_UnderwritingCaseMember__c(
                Id = String.valueOf(ucMemberMap.get('Id')),
                ARC_ReviewedBy__c = userId,
                ARC_ApprovalResolution__c = String.valueOf(ucMemberMap.get('ARC_ApprovalResolution__c')),
                ARC_Score__c = (String.valueOf(ucMemberMap.get('ARC_Score__c')) != null && String.valueOf(ucMemberMap.get('ARC_Score__c')) != '') ? decimal.valueOf(String.valueOf(ucMemberMap.get('ARC_Score__c'))) : null,
                ARC_Description__c = String.valueOf(ucMemberMap.get('ARC_Description__c'))
            );
            underwritingCaseMembers.add(underCaseMember);
        }
        update new Case(Id = caseId, ARC_ReviewedBy__c = userId);
        update underwritingCaseMembers;
    }

    @AuraEnabled
    public static void closeCase(String status, Id caseId, String cancelReason){
        Case caseToUpdate = new Case(
            Id = caseId, 
            Status = status
        );
        update caseToUpdate;

        System.debug(caseId);
        if(status == 'Closed Rejected' || status == 'Closed Voided'){
            Case workingCase = [SELECT Id, ARC_Contract__c FROM Case WHERE Id =:caseId];
            if(workingCase?.ARC_Contract__c != null){
                Contract caseContract = new Contract(
                    Id = workingCase.ARC_Contract__c,
                    Status = 'Voided',
                    ARC_CancellationReason__c = cancelReason
                );
                update caseContract;
            }
        }
        
    }
}