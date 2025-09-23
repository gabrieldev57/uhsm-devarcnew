global class ARC_RepriceCase  {
    global static Id contractId;

    @AuraEnabled(cacheable = false) 
    global static Boolean repriceCase(String caseId){
        List<Case> listOfCases = [SELECT Id,ARC_Contract__c,ARC_SignatureCompleted__c,ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c, ARC_Contract__r.Status,Type, ARC_Contract__r.ARC_ContractReason__c FROM Case WHERE Id = :caseId];
        return true;
    }

    @AuraEnabled 
    global static List<ARC_UnderwritingCaseMember__c> getUnderwritingCaseMembers(String caseId){
        
        List<ARC_UnderwritingCaseMember__c> ucMembers = [SELECT id,arc_underwritingcase__c,arc_underwritingcase__r.status,arc_member__c,name,arc_approvalresolution__c FROM ARC_UnderwritingCaseMember__c WHERE (ARC_UnderwritingCase__c = :caseId)];
        return ucMembers;
    }
    @AuraEnabled
    global static List<Case> getCase(String caseId){
        List<Case> caseData = [SELECT Id,Case.Owner.Type,Status,ARC_Contract__c,ARC_SignatureCompleted__c,ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c, ARC_Contract__r.Status,Type, ARC_Contract__r.ARC_ContractReason__c FROM Case WHERE Id = :caseId];
        return caseData;
    }


    @AuraEnabled(cacheable = false)
    global static Map<String,Object> getCaseForUpdate(String caseId, Id currentUserId){
        Map<String, Object> response = new Map<String, Object>();
        try {
            Case caseRecord = [SELECT Id,Case.Owner.Type,Status,ARC_Contract__c,ARC_SignatureCompleted__c,ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c, ARC_Contract__r.Status,Type, ARC_Contract__r.ARC_ContractReason__c FROM Case WHERE Id = :caseId FOR UPDATE];


            caseRecord.Status = caseRecord.Status == 'New' ? 'In Progress' : caseRecord.Status; 
            caseRecord.OwnerId = caseRecord.Owner.Type == 'User' ? caseRecord.OwnerId : currentUserId;

            //if the case owner is a user, throw an error
            if(caseRecord.Owner.Type == 'User'){
                response.put('isSuccess', false);
                return response;
            }else{

                /* Set a delay of 11 seconds lock on the record so if another user tries to updates the same record at the same time it fails
                https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_locking_statements.htm */
                Long startTime = Datetime.now().getTime();
                while (true) {
                    // Calculate the difference in milliseconds seconds and divide it by 1000 to convert it to seconds
                    if ((Datetime.now().getTime() - startTime) / 1000 > 11) {
                        break;
                    }
                }
    
                Database.SaveResult saveResult = Database.update(caseRecord);
                
                if(saveResult.isSuccess()){
                    response.put('isSuccess', true);
                    response.put('caseRecord', caseRecord);
                } else {
                    response.put('isSuccess', false);
                }
                return response;
            }
        } catch (Exception e) {
            response.put('isSuccess', false);
            return response;
        }
    }
}