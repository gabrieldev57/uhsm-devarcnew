trigger CareRequestMain on CareRequest (after insert, after update) {
    if((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter){
       Map<String, String> caseToAccountIdMap = new Map<String,String>();
       for(CareRequest eachRequest : trigger.new){    
           if(String.isNotBlank(eachRequest.MemberId)){
               if((Trigger.isUpdate && (Trigger.oldMap.get(eachRequest.Id).MemberId != eachRequest.MemberId)) || Trigger.isInsert)
               caseToAccountIdMap.put(eachRequest.CareRequestCaseId, eachRequest.MemberId);
           }
       }
       if(caseToAccountIdMap.size() > 0){
           List<Case> caseList = [Select id, Member__c from Case where Id in: caseToAccountIdMap.keyset()];
           for(Case eachCase : caseList){    
              eachCase.Member__c = caseToAccountIdMap.get(eachCase.Id);
           }
           try{    
               update caseList;
           }
           catch(Exception ex){}
       } 
    }
}