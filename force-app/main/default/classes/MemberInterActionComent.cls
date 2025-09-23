global class MemberInterActionComent implements Database.Batchable<sObject> {
    private String InteractionId;
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator([
            SELECT Id,Pure_Cloud_Id__c,Description__c,Notes__c FROM ARC_MemberInteraction__c 
        ]);
    }
    global void execute(Database.BatchableContext BC, List<ARC_MemberInteraction__c> members){
        // process each batch of records
       System.debug('Memebr Interaction record :' + members );
       List<ARC_MemberInteraction__c> memberInteractionsToInsert = new List<ARC_MemberInteraction__c>();
       
     //  String comments,descirption,notes,isolatedId; 
       String regexUUID   = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'; // Assumes the ID follows a UUID format
       String regexHex = '[0-9a-fA-F]{32}'; // 32-character hexadecimal string
       String interactionComent; 
        
        for(ARC_MemberInteraction__c member : members){
            
              
            List<ARC_MemberInteractionComment__c> memberInteractioncoments=[SELECT Id,Comment__c,MemberInteractionId__c FROM ARC_MemberInteractionComment__c WHERE MemberInteractionId__c =: member.Id ORDER BY Id DESC LIMIT 1];
           System.debug('memberInteractioncoments :' + memberInteractioncoments );
            if(memberInteractioncoments.size() > 0){
                interactionComent=memberInteractioncoments[0].Comment__c;
            }else{
                interactionComent='abc';
            }
            String[] fieldsToCheck = new String[]{member.Description__c, member.Notes__c,interactionComent };
        	Matcher matcherUUID, matcherHex;

        	for (String field : fieldsToCheck) {
            if (field != null) {
                matcherUUID = Pattern.compile(regexUUID).matcher(field);
                matcherHex = Pattern.compile(regexHex).matcher(field);

                if (matcherUUID.find()) {
                    member.Pure_Cloud_Id__c = matcherUUID.group();
                    memberInteractionsToInsert.add(member);
                    System.debug('Isolated UUID: ' + matcherUUID.group());
                    break;
                } else if (matcherHex.find()) {
                    member.Pure_Cloud_Id__c = matcherHex.group();
                    memberInteractionsToInsert.add(member);
                    System.debug('Isolated 32-character Hex ID: ' + matcherHex.group());
                    break;
                }else{
                    System.debug('Match not found ' );
                }
            }
           }
        }
        if (!memberInteractionsToInsert.isEmpty()) {
        	 System.debug('memberInteractionsToInsert: ' + memberInteractionsToInsert);
      		   update memberInteractionsToInsert;
    	
       }    
    }
             
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    //    System.debug('InteractionId2 :' + InteractionId);
    }
}